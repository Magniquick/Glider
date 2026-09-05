#!/usr/bin/env python3
"""Drive a running Glider build over the VM service.

Pairs with the `ext.glider.*` extensions in `lib/app/bootstrap/dev_controls.dart`,
which exist only outside release builds. Profiling a gesture otherwise needs
someone tapping at the right moment, which is slow to iterate on and impossible
to repeat exactly.

    uv run --with websockets tool/glider_ctl.py <ws-uri> tree
    uv run --with websockets tool/glider_ctl.py <ws-uri> collapse --biggest 1
    uv run --with websockets tool/glider_ctl.py <ws-uri> profile-collapse

`profile-collapse` is the whole measurement in one pass: reset the allocation
counters and timeline, collapse the biggest comment, then report what that cost.
"""
import argparse
import asyncio
import json
import sys

import websockets


class Vm:
    def __init__(self, ws):
        self.ws = ws
        self.n = 0
        self.isolate = None

    async def call(self, method, params=None, timeout=180):
        self.n += 1
        rid = str(self.n)
        await self.ws.send(json.dumps({"jsonrpc": "2.0", "id": rid,
                                       "method": method,
                                       "params": params or {}}))
        while True:
            msg = json.loads(await asyncio.wait_for(self.ws.recv(), timeout))
            if msg.get("id") == rid:
                if "error" in msg:
                    raise RuntimeError(f"{method}: {msg['error']}")
                return msg["result"]

    async def attach(self):
        vm = await self.call("getVM")
        self.isolate = next(i["id"] for i in vm["isolates"]
                            if i["name"] == "main")

    async def ext(self, name, **params):
        result = await self.call(name, {"isolateId": self.isolate, **params})
        # Extension results arrive as a JSON string under a wrapper.
        if isinstance(result, dict) and "result" in result:
            return json.loads(result["result"])
        return result

    async def allocation(self):
        """Per-class allocation counters, as a snapshot to be differenced.

        `getAllocationProfile(reset: true)` silently does nothing on this VM:
        `accumulatedSize` reads the same before and after. The counters only
        ever grow, so two reads either side of a gesture give the real cost
        and a single read gives the whole lifetime of the app.
        """
        result = await self.call("getAllocationProfile",
                                 {"isolateId": self.isolate})
        return {member["class"]["name"]:
                (member.get("accumulatedSize", 0),
                 member.get("instancesAccumulated", 0))
                for member in result.get("members", [])}

    @staticmethod
    def allocation_delta(before, after):
        rows = []
        for name, (size, count) in after.items():
            was_size, was_count = before.get(name, (0, 0))
            if size - was_size > 0:
                rows.append((size - was_size, count - was_count, name))
        rows.sort(reverse=True)
        return sum(row[0] for row in rows), rows

    async def micros(self):
        return (await self.call("getVMTimelineMicros"))["timestamp"]

    async def stacks(self, origin, extent):
        """Hottest call stacks between two timestamps, as sample counts.

        Class totals say what was allocated but never who allocated it, which
        is the only part that says what to change.
        """
        samples = await self.call("getCpuSamples",
                                  {"isolateId": self.isolate,
                                   "timeOriginMicros": origin,
                                   "timeExtentMicros": extent})
        functions = samples.get("functions", [])
        leaves, inclusive = {}, {}
        for sample in samples.get("samples", []):
            stack = sample.get("stack", [])
            if not stack:
                continue
            leaves[stack[0]] = leaves.get(stack[0], 0) + 1
            for index in set(stack):
                inclusive[index] = inclusive.get(index, 0) + 1
        return len(samples.get("samples", [])), functions, leaves, inclusive

    async def frames(self):
        events = (await self.call("getVMTimeline")).get("traceEvents", [])
        spans = {}
        stacks = {}
        for e in events:
            name, ph = e.get("name"), e.get("ph")
            if ph == "B":
                stacks.setdefault((name, e["tid"]), []).append(e["ts"])
            elif ph == "E":
                st = stacks.get((name, e["tid"]))
                if st:
                    spans.setdefault(name, []).append(e["ts"] - st.pop())
        return spans




async def build_costs(vm, phase="BUILD"):
    """Self time per span, restricted to the inside of the worst `phase` span.

    Aggregating the whole window buries a single 30 ms frame under seconds of
    idle GC. The only interesting question is what ran inside that one frame.
    """
    events = (await vm.call("getVMTimeline")).get("traceEvents", [])
    events.sort(key=lambda e: e.get("ts", 0))

    spans, stacks = [], {}
    for e in events:
        ph, name, tid = e.get("ph"), e.get("name"), e.get("tid")
        if ph == "B":
            stacks.setdefault(tid, []).append((name, e["ts"], len(spans)))
            spans.append([name, e["ts"], None, tid, 0])
        elif ph == "E":
            stack = stacks.get(tid)
            if not stack:
                continue
            name, start, index = stack.pop()
            spans[index][2] = e["ts"]
            if stack:
                spans[stack[-1][2]][4] += e["ts"] - start
        elif ph == "X" and e.get("dur") is not None:
            spans.append([name, e["ts"], e["ts"] + e["dur"], tid, 0])

    candidates = [s for s in spans if s[0] == phase and s[2] is not None]
    if not candidates:
        return None, {}, {}, {}
    worst = max(candidates, key=lambda s: s[2] - s[1])

    self_us, incl_us, counts = {}, {}, {}
    for name, start, end, tid, children in spans:
        if end is None or tid != worst[3]:
            continue
        if start < worst[1] or end > worst[2]:
            continue
        self_us[name] = self_us.get(name, 0) + (end - start) - children
        incl_us[name] = incl_us.get(name, 0) + (end - start)
        counts[name] = counts.get(name, 0) + 1
    return (worst[2] - worst[1]), self_us, incl_us, counts


async def tap_row(vm, env, target_id, verbose=False):
    """Click the row for `target_id`, confirming by what actually collapsed.

    The row is put at the top of the viewport first, so the tap only has to
    sweep down from the app bar until the right comment toggles. Aiming
    blindly would silently measure a tap on the wrong row.
    """
    await vm.ext("ext.glider.scroll", id=str(target_id), jump="true")
    await asyncio.sleep(1.5)
    x = env["width"] / 2
    for y in range(90, int(env["height"]) - 40, 24):
        before = set((await vm.ext("ext.glider.tree"))["collapsed"])
        if target_id in before:
            return {"already": True, "y": y}
        await vm.ext("ext.glider.tap", x=str(x), y=str(float(y)))
        await asyncio.sleep(0.7)
        after = set((await vm.ext("ext.glider.tree"))["collapsed"])
        if target_id in after:
            return {"hit": True, "y": y}
        for wrong in after - before:
            # Undo a tap that landed on a neighbour, so the sweep stays clean.
            await vm.ext("ext.glider.collapse", id=str(wrong),
                         collapsed="false")
            await asyncio.sleep(0.3)
        if verbose:
            print(f"  y={y} hit nothing useful")
    return {"hit": False}


async def main(uri, args):
    async with websockets.connect(uri, max_size=None, open_timeout=15) as ws:
        vm = Vm(ws)
        await vm.attach()

        if args.command == "env":
            print(json.dumps(await vm.ext("ext.glider.env"), indent=2))
            return

        if args.command == "tree":
            print(json.dumps(await vm.ext("ext.glider.tree"), indent=2))
            return

        if args.command == "scroll":
            print(json.dumps(await vm.ext(
                "ext.glider.scroll",
                jump="true" if args.jump else "false",
                **({"id": str(args.id)} if args.id
                   else {"index": str(args.index)}))))
            return

        if args.command == "profile-builds":
            # Tracing every widget build costs several ms a frame by itself,
            # so it stays off unless the run is explicitly drilling in.
            # Tracing both floods the timeline ring buffer and the frame we
            # care about gets evicted before it can be read, so each is
            # switched on only when that phase is the one being opened up.
            wanted = {
                "ext.flutter.profileWidgetBuilds": args.trace_widgets,
                "ext.flutter.profileRenderObjectLayouts": args.trace_layouts,
            }
            for ext_name, on in wanted.items():
                try:
                    await vm.call(ext_name, {"isolateId": vm.isolate,
                                             "enabled": str(on).lower()})
                    print(f"{ext_name}: {'on' if on else 'off'}")
                except RuntimeError as error:
                    print(f"{ext_name}: {error}")
            if args.analyze_only:
                # Whatever is already in the timeline, usually a gesture a
                # person just made by hand, which is the one that counts.
                frames = (await vm.ext("ext.glider.frames"))["frames"]
                if frames:
                    slowest = max(frames, key=lambda f: f["total"])
                    print(f"slowest frame {slowest['total'] / 1000:.1f} ms "
                          f"(build {slowest['build'] / 1000:.1f})")
                width, self_us, incl_us, counts = await build_costs(vm,
                                                                    args.phase)
                if width is None:
                    print(f"no {args.phase} span recorded")
                    return
                print(f"\nworst {args.phase} span: {width / 1000:.1f} ms, "
                      f"{sum(counts.values())} spans inside it\n")
                print(f"{'self ms':>8} {'incl ms':>8} {'count':>7}  widget")
                for name in sorted(self_us, key=lambda n: -self_us[n])[:28]:
                    print(f"{self_us[name] / 1000:8.1f} "
                          f"{incl_us.get(name, 0) / 1000:8.1f} "
                          f"{counts[name]:7d}  {name}")
                return

            tree = await vm.ext("ext.glider.tree")
            target_id = args.id or tree["roots"][(args.biggest or 1) - 1]["id"]
            env = await vm.ext("ext.glider.env")

            await vm.ext("ext.glider.collapse", id=str(target_id),
                         collapsed="false")
            await asyncio.sleep(1.5)
            await vm.ext("ext.glider.scroll", id=str(target_id), jump="true")
            await asyncio.sleep(2.5)

            await vm.call("setVMTimelineFlags",
                          {"recordedStreams": ["Dart", "Embedder", "GC"]})
            await vm.call("clearVMTimeline")
            await vm.ext("ext.glider.frames", reset="true")
            hit = await tap_row(vm, env, target_id)
            await asyncio.sleep(2)

            frames = (await vm.ext("ext.glider.frames"))["frames"]
            slowest = max(frames, key=lambda f: f["total"]) if frames else None
            if slowest:
                print(f"slowest frame {slowest['total'] / 1000:.1f} ms "
                      f"(build {slowest['build'] / 1000:.1f})  tap={hit}")

            for phase in ("BUILD", "LAYOUT", "SEMANTICS", "PAINT",
                          "COMPOSITING"):
                got, _, _, _ = await build_costs(vm, phase)
                if got is not None:
                    print(f"  worst {phase:12s} {got / 1000:7.2f} ms")

            width, self_us, incl_us, counts = await build_costs(vm,
                                                                 args.phase)
            if width is None:
                print(f"no {args.phase} span recorded")
                return
            print(f"\nworst {args.phase} span: {width / 1000:.1f} ms, "
                  f"{sum(counts.values())} spans inside it\n")
            print(f"{'self ms':>8} {'incl ms':>8} {'count':>7}  widget")
            for name in sorted(self_us, key=lambda n: -self_us[n])[:25]:
                print(f"{self_us[name] / 1000:8.1f} "
                      f"{incl_us.get(name, 0) / 1000:8.1f} "
                      f"{counts[name]:7d}  {name}")
            return

        if args.command == "tap":
            env = await vm.ext("ext.glider.env")
            print(await tap_row(vm, env, args.id, verbose=True))
            return

        if args.command == "budget":
            print(json.dumps(await vm.ext("ext.glider.budget",
                                          micros=str(args.micros))))
            return

        if args.command == "cache":
            print(json.dumps(await vm.ext(
                "ext.glider.cache",
                **({"pixels": str(args.pixels)} if args.pixels is not None
                   else {}))))
            return

        if args.command == "frames":
            if args.reset:
                await vm.ext("ext.glider.frames", reset="true")
                print("frame recorder zeroed; drive the app, then read it back")
                return

            frames = (await vm.ext("ext.glider.frames"))["frames"]
            if not frames:
                print("no frames recorded")
                return
            budget = 1000000 / args.hz
            over = [f for f in frames if f["total"] > budget]
            totals = sorted(f["total"] / 1000 for f in frames)
            print(f"{len(frames)} frames, {len(over)} over "
                  f"{budget / 1000:.1f} ms, {sum(f['total'] for f in over) / 1000:.0f} ms lost")
            for label, value in (("p50", totals[len(totals) // 2]),
                                 ("p90", totals[int(len(totals) * 0.9)]),
                                 ("p99", totals[int(len(totals) * 0.99)]),
                                 ("max", totals[-1])):
                print(f"  {label} {value:8.1f} ms")
            print("worst frames (build / raster):")
            for f in sorted(frames, key=lambda f: -f["total"])[:8]:
                print(f"  {f['total'] / 1000:8.1f} ms  "
                      f"{f['build'] / 1000:7.1f} / {f['raster'] / 1000:.1f}")
            return

        if args.command == "collapse":
            params = {}
            if args.id:
                params["id"] = str(args.id)
            elif args.biggest:
                params["biggest"] = str(args.biggest)
            params["collapsed"] = "false" if args.expand else "true"
            print(json.dumps(await vm.ext("ext.glider.collapse", **params)))
            return

        if args.command == "profile-collapse":
            if args.pixels is not None:
                await vm.ext("ext.glider.cache", pixels=str(args.pixels))
            if args.micros is not None:
                await vm.ext("ext.glider.budget", micros=str(args.micros))
            tree = await vm.ext("ext.glider.tree")
            target_id = args.id or tree["roots"][(args.biggest or 1) - 1]["id"]
            print(f"thread {tree['itemId']}: {tree['rows']} rows, "
                  f"collapsing {target_id}")

            budget = 1000000 / args.hz
            worst = []
            for run in range(args.repeat):
                # Measuring the expand means starting from collapsed, and the
                # rows it restores have to be measured all over again.
                await vm.ext("ext.glider.collapse", id=str(target_id),
                             collapsed="true" if args.measure_expand
                             else "false")
                await asyncio.sleep(1.5)
                # Real reading scrolls past every row on the way down, and
                # each one it touches is kept alive from then on. Landing
                # directly on the target accumulates nothing, so it measures a
                # fresher list than anybody actually has.
                if args.walk:
                    if args.measure_walk:
                        await vm.ext("ext.glider.frames", reset="true")
                    for index in range(0, tree["rows"], args.walk):
                        await vm.ext("ext.glider.scroll", index=str(index),
                                     jump="true")
                        await asyncio.sleep(0.12)
                    await asyncio.sleep(1.5)

                if args.warm is not None:
                    await vm.ext("ext.glider.scroll", index=str(args.warm),
                                 jump="true")
                    await asyncio.sleep(1.5)
                if not args.offscreen:
                    await vm.ext("ext.glider.scroll", id=str(target_id),
                                 jump="true" if args.jump else "false")
                    await asyncio.sleep(2.5)

                if args.tap:
                    env = await vm.ext("ext.glider.env")
                    await vm.ext("ext.glider.scroll", id=str(target_id),
                                 jump="true")
                    await asyncio.sleep(2)

                if not args.measure_walk:
                    await vm.ext("ext.glider.frames", reset="true")
                await vm.call("setFlag", {"name": "profile_period",
                                          "value": "100"})
                origin = await vm.micros()
                if args.tap:
                    hit = await tap_row(vm, env, target_id)
                    if not hit.get("hit") and not hit.get("already"):
                        print("could not land a tap on that row")
                        return
                    result = {"id": target_id}
                else:
                    result = await vm.ext("ext.glider.collapse",
                                          id=str(target_id),
                                          collapsed="false"
                                          if args.measure_expand else "true")
                    if not result["changed"]:
                        print("already collapsed; nothing was measured")
                        return
                await asyncio.sleep(2)

                extent = await vm.micros() - origin
                frames = (await vm.ext("ext.glider.frames"))["frames"]
                if not frames:
                    print(f"  run {run + 1}: no frames at all")
                    continue
                over = [f for f in frames if f["total"] > budget]
                slowest = max(frames, key=lambda f: f["total"])
                worst.append(slowest["total"] / 1000)
                print(f"  run {run + 1}: {len(frames):3d} frames, "
                      f"{len(over):3d} over {budget / 1000:.1f} ms, "
                      f"slowest {slowest['total'] / 1000:7.1f} ms "
                      f"(build {slowest['build'] / 1000:.1f}, "
                      f"raster {slowest['raster'] / 1000:.1f}), "
                      f"lost {sum(f['total'] for f in over) / 1000:6.1f} ms")

            count, functions, leaves, inclusive = await vm.stacks(origin,
                                                                  extent)
            if count:
                def name_of(index):
                    fn = functions[index].get("function", {})
                    owner = fn.get("owner", {})
                    if owner.get("type") == "@Class" and owner.get("name"):
                        return f"{owner['name']}.{fn.get('name', '?')}"
                    return fn.get("name", "?")

                print(f"\nlast run, {count} samples. self time:")
                for index, hits in sorted(leaves.items(),
                                          key=lambda kv: -kv[1])[:14]:
                    print(f"  {100 * hits / count:5.1f}%  {name_of(index)}")
                print("inclusive, app code only:")
                for index, hits in sorted(inclusive.items(),
                                          key=lambda kv: -kv[1]):
                    label = name_of(index)
                    uri = functions[index].get("location", {}).get(
                        "script", {}).get("uri", "")
                    if "package:glider" in uri and hits > count * 0.02:
                        print(f"  {100 * hits / count:5.1f}%  {label}")

            if worst:
                worst.sort()
                print(f"slowest frame, median of {len(worst)}: "
                      f"{worst[len(worst) // 2]:.1f} ms "
                      f"(min {worst[0]:.1f}, max {worst[-1]:.1f})")
            return

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("uri")
    parser.add_argument("command",
                        choices=["env", "tree", "scroll", "collapse",
                                 "frames", "tap", "cache", "budget",
                                 "profile-builds",
                                 "profile-collapse"])
    parser.add_argument("--id", type=int)
    parser.add_argument("--biggest", type=int)
    parser.add_argument("--index", type=int)
    parser.add_argument("--pixels", type=float)
    parser.add_argument("--micros", type=int)
    parser.add_argument("--trace-layouts", action="store_true",
                        help="emit a span per render object layout")
    parser.add_argument("--trace-widgets", action="store_true",
                        help="emit a span per widget build, costs a few ms")
    parser.add_argument("--analyze-only", action="store_true",
                        help="read the timeline as-is, drive nothing")
    parser.add_argument("--phase", default="BUILD",
                        help="frame phase to open up (BUILD, LAYOUT, ...)")
    parser.add_argument("--tap", action="store_true",
                        help="collapse with a real pointer event, as a reader would")
    parser.add_argument("--reset", action="store_true",
                        help="zero the frame recorder and record from now on")
    parser.add_argument("--expand", action="store_true",
                        help="expand instead of collapse")
    parser.add_argument("--offscreen", action="store_true",
                        help="do not scroll to the row first")
    parser.add_argument("--measure-walk", action="store_true",
                        help="time the scrolling itself, not the gesture")
    parser.add_argument("--walk", type=int,
                        help="step through the list first, in this stride")
    parser.add_argument("--measure-expand", action="store_true",
                        help="time the expand instead of the collapse")
    parser.add_argument("--repeat", type=int, default=5,
                        help="how many times to measure the same collapse")
    parser.add_argument("--hz", type=float, default=60.0,
                        help="frame budget to count drops against")
    parser.add_argument("--warm", type=int,
                        help="visit this row first, then return to the target")
    parser.add_argument("--jump", action="store_true",
                        help="land on the row instead of animating to it")
    parser.add_argument("--idle", action="store_true",
                        help="measure the same window without collapsing")
    asyncio.run(main(sys.argv[1], parser.parse_args()))
