#!/bin/bash
#
# Create "$2" as a softlink to "$1".
# Perform a copy instead if softlinks are not supported.
#
# stable: do not treat existing destination directories differently.
# secure: do not remove things, instead do a backup.
# idempotent: do nothing if called multiple with the same arguments.
#
# Note that MACshim https://github.com/hilbix/macshim
# does not support this here yet, hence some (untested) hack at the end.

[ 2 = $# ] || { echo "Usage: $0 from to" >&2; exit 1; };

from="$(readlink -e "$1")";
to="$(readlink -e "$2")";

: same softlink;
[ ".$from" = ".$to" ] && exit;

: same content;
cmp -s "$1" "$2" && exit;

dst="$(dirname -- "$2")";
[ -d "$dst" ] || mkdir -pm700 "$dst" || exit;

: try to link;
ln --relative -s -v --backup=t -T "$from" "$2" && exit;

: fallback to copy;
cp -f --backup=t -T "$1" "$2" && exit;

: hack for MACs, needs MACshim;
[ -d "$2" ] && { echo "$2 is a directory"; exit 1; };
cp -f --backup=t "$1" "$2" && exit;

