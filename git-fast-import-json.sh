#!/bin/bash
#
# Converts fast-export's binary data into single line json strings for easy postprocessing
# See git-fast-export-json for counterpart

git fast-export "$@" > >(
exec python3 -c '

import sys
import json

while	1:
	a	= sys.stdin.readline()
	if not a: break
	if a[0:5] != "json ":
		sys.stdout.write(a)
		continue
	d = json.loads(a[5:])
	sys.stdout.write(f"data {len(d)}\n")
	sys.stdout.write(d)
'
)

