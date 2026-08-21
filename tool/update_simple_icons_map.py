#!/usr/bin/env python3
"""Regenerates assets/simple_icons/domains.json.

Simple Icons records a `source` URL for every brand, which is almost always
the brand's own site. That gives us a domain -> slug index for free, with no
hand-maintained list to drift out of date. The pinned package version travels
in the same file, so the map and the CDN URLs it implies can never disagree.

Usage: python3 tool/update_simple_icons_map.py [version]
"""
import json, re, sys, unicodedata, urllib.request

OUT = 'assets/simple_icons/domains.json'

# Brands whose `source` URL cannot identify their domain, hand-checked against
# 30 days of Hacker News front pages. Every entry is verified to exist in the
# dataset at generation time, so a rename upstream fails the build loudly
# rather than silently dropping an icon.
OVERRIDES = {
    # Renamed brand: the icon is filed under x, and twitter.com's only
    # claimant in the data is LibraryThing, which would map it to the wrong
    # logo entirely.
    'twitter.com': 'x',
    'x.com': 'x',
    # Brand name and domain simply differ.
    'nytimes.com': 'newyorktimes',
    'theregister.com': 'theregister',
    # Sourced from Wikimedia Commons, which says nothing about the domain.
    'wikipedia.org': 'wikipedia',
    'techcrunch.com': 'techcrunch',
    # Sourced from a marketing subdomain of another Google property.
    'google.com': 'google',
    'blog.google': 'google',
    'claude.com': 'claude',
}


def fetch(url):
    with urllib.request.urlopen(url, timeout=60) as f:
        return json.load(f)


def slugify(title):
    # Mirrors simple-icons' own slug rules.
    t = title.lower()
    for a, b in (('+', 'plus'), ('.', 'dot'), ('&', 'and'), ("'", ''),
                 ('!', ''), ('à', 'a'), ('ã', 'a'), ('ä', 'a'), ('ç', 'c'),
                 ('é', 'e'), ('ë', 'e'), ('í', 'i'), ('ð', 'd'), ('ñ', 'n'),
                 ('ö', 'o'), ('ū', 'u'), ('ĕ', 'e')):
        t = t.replace(a, b)
    t = unicodedata.normalize('NFD', t)
    t = ''.join(c for c in t if unicodedata.category(c) != 'Mn')
    return re.sub(r'[^a-z0-9]', '', t)


def plain(title):
    """Title with punctuation simply removed, so Node.js matches nodejs.org."""
    return re.sub(r'[^a-z0-9]', '', title.lower())


def main():
    version = sys.argv[1] if len(sys.argv) > 1 else fetch(
        'https://registry.npmjs.org/simple-icons/latest')['version']
    data = fetch(f'https://cdn.jsdelivr.net/npm/simple-icons@{version}'
                 '/data/simple-icons.json')
    icons = data['icons'] if isinstance(data, dict) else data

    claims = {}
    for icon in icons:
        match = re.match(r'https?://([^/]+)', icon.get('source', ''))
        if not match:
            continue
        host = re.sub(r'^www\.', '', match.group(1)).lower()
        claims.setdefault(host, []).append(
            (icon.get('slug') or slugify(icon['title']), icon['title']))

    # A domain is only usable when it is unambiguous. Thousands of brands list
    # a github.com source URL, so taking the first claimant would map the whole
    # of GitHub to whichever project sorts first. Where several brands claim a
    # domain, keep it only for the one whose slug is the domain's own name.
    domains = {}
    for host, entries in claims.items():
        own = host.split('.')[-2] if host.count('.') else host
        for slug, title in entries:
            if slug == slugify(own) or plain(title) == own:
                domains[host] = slug
                break

    # Brands often list a subdomain as their source -- GitLab points at
    # about.gitlab.com -- while links in the wild use the bare domain. Fold
    # those in, but only where the slug is the registrable domain's own name,
    # so a project hosted on someone else's domain cannot claim it.
    for host in claims:
        parts = host.split('.')
        if len(parts) < 3:
            continue
        registrable = '.'.join(parts[-2:])
        if registrable in domains:
            continue
        for slug, title in claims[host]:
            if slug == slugify(parts[-2]) or plain(title) == parts[-2]:
                domains[registrable] = slug
                break

    known = {icon.get('slug') or slugify(icon['title']) for icon in icons}
    missing = {d: s for d, s in OVERRIDES.items() if s not in known}
    if missing:
        raise SystemExit(f'overrides reference slugs that no longer exist: '
                         f'{missing}. Check simple-icons {version}.')
    domains.update(OVERRIDES)

    with open(OUT, 'w') as f:
        json.dump({'version': version, 'domains': domains}, f,
                  separators=(',', ':'), sort_keys=True)
    print(f'{OUT}: {len(domains)} domains from simple-icons {version}')


if __name__ == '__main__':
    main()
