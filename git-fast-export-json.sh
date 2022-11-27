#!/bin/bash
#
# Converts fast-export's binary data into single line json strings for easy postprocessing
# See git-fast-import-json for counterpart.

git fast-export "$@" > >(
exec python3 -c '
import sys
import json
ISO="iso-8859-1"

while	1:
	a	= sys.stdin.buffer.readline()
	if not a: break
	if a[0:5] != b"data ":
		sys.stdout.buffer.write(a)
		continue
	n = int(a[5:].decode(ISO).rstrip("\n"))
	assert a == f"data {n}\n".encode(), f"incorrectly parsed {a}: {n}"
	if n == 0: continue
	sys.stdout.buffer.write(b"json ")
	json.dump(sys.stdin.buffer.read(n).decode(ISO), fp=sys.stdout)
	sys.stdout.flush()
	sys.stdout.buffer.write(b"\n")
'
)

