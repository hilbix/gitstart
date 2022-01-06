#!/bin/bash
#
# Converts fast-export's binary data into single line json strings for easy postprocessing
# See git-fast-import-json for counterpart.

git fast-export "$@" > >(
exec python3 -c '

import sys
import json

while	1:
	a	= sys.stdin.readline()
	if not a: break
	if a[0:5] != "data ":
		sys.stdout.write(a)
		continue
	n = int(a[5:].rstrip("\n"))
	assert a == f"data {n}\n", f"incorrectly parsed {a}: {n}"
	if n == 0: continue
	d = sys.stdin.read(n)
	sys.stdout.write("json ")
	json.dump(d, fp=sys.stdout)
	sys.stdout.write("\n")
'
)

