#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Regenerates assets/public_suffix_list.dat.

Comments and blank lines are stripped; rules are kept verbatim and in order,
including the wildcard and exception forms the matching algorithm needs. The
ICANN and PRIVATE sections are both kept: github.io and blogspot.com live in
the private section, and those are precisely the ones that matter here -- each
user's Pages site is its own site, not a subdomain of GitHub's.

Usage: python3 tool/update_public_suffix_list.py
"""
import urllib.request

SOURCE = 'https://publicsuffix.org/list/public_suffix_list.dat'
OUT = 'assets/public_suffix_list.dat'

with urllib.request.urlopen(SOURCE, timeout=60) as f:
    body = f.read().decode('utf8')

rules = [line.strip() for line in body.splitlines()
         if line.strip() and not line.startswith('//')]
with open(OUT, 'w') as f:
    f.write('\n'.join(rules) + '\n')
print(f'{OUT}: {len(rules)} rules')
