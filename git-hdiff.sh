#!/bin/bash
#
# history-diff to a branch
#
# Checks if all files in the worktree are known in the branch or the branch's history
# UNKNOWN are the files which are unknown in the worktree
# NEW are the files which are new
# DIFF are the files which differ, so have some local changes unknown to branch
# SPACES are notified, just in case you have some local cleanup compared to the branch

STDOUT() { local e=$?; printf %q "$1"; [ 1 = $# ] || printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@" >&2; return $e; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
x() { STDERR exec: "$@"; "$@"; STDERR rc=$?: "$@"; }
x() { "$@"; STDERR rc=$?: "$@"; }
x() { "$@"; }
o() { x "$@" || OOPS rc=$?: "$@"; }
v() { set -- "$1" "$(o "${@:2}" && echo x)" || OOPS rc=$? setting "$1"; set -- "$1" "${2%x}"; declare -g "$1=${2%$'\n'}"; }

branch="${1:-master}"

[ 1 -ge "$#" ] || OOPS Usage: "$0" BRANCH

v SHA git rev-parse --verify --quiet "$branch^{commit}"

ok=0
mis=0
new=0
spc=0
mod=0

# Find DIFFs to master
git diff -z --name-only "$SHA" |
while read -rd '' name
do
	if	[ ! -f "$name" ]
	then
		echo "UNKNOWN: $name (in $branch but not here)"
		let mis++
		continue
	fi
	MIN=
	HIT=
	while read -r sha
	do
		THING="$(git cat-file -p "$sha:$name" 2>/dev/null && echo x)" || continue
		THING="${THING%x}"
#		echo -n "$sha."
		if echo -n "$THING" | x cmp -s -- "$name" -
		then
#			echo "OK: $name"
			let ok++
			continue 2
		fi
		n="$(echo -n "$THING" | diff -bu -- "$name" - | wc -l)"
		[ -n "$MIN" ] && [ "$MIN" -le "$n" ] || { MIN="$n"; HIT="$sha:$name"; }
	done < <(git log --follow --pretty=tformat:%H "$SHA" -- "$name")

	if [ -z "$HIT" ]
	then
		let new++
		echo "NEWFILE: $name (nowhere in $branch)"
		continue
	fi

	if [ 0 = "$MIN" ]
	then
		let spc++
		printf 'SPACES:: git diff %q -- %q\n' "${HIT%%:*}" "$name"
		continue
	fi

	let mod++
	printf 'MODIFIED: git diff %q -- %q\n' "${HIT%%:*}" "$name"
	git diff -bu "${HIT%%:*}" -- "$name"
done

echo
echo "hdiff $branch summary: OK=$ok UNKNOWN=$mis NEW=$new SPC=$spc DIFF=$mod"

