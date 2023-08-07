#!/bin/bash
#
#U Usage: git hdiff [branch]
#U	history-diff to a branch, default: master
#U	Checks if all files in the worktree are known in the branch or the branch's history
#U	UNKNOWN are the files which are unknown in the worktree
#U	NEW are the files which are new
#U	DIFF are the files which differ, so have some local changes unknown to branch
#U	SPACES are notified, just in case you have some local cleanup compared to the branch

STDOUT() { local e=$?; printf %q "$1"; [ 1 = $# ] || printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@" >&2; return $e; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
x() { STDERR exec: "$@"; "$@"; STDERR rc=$?: "$@"; }
x() { "$@"; STDERR rc=$?: "$@"; }
x() { "$@"; }
i() { set -- $? "$@"; "${@:2}"; return $1; }
o() { x "$@" || OOPS rc=$?: "$@"; }
v() { set -- "$1" "$(o "${@:2}" && echo x)"; set -- "$1" "${2%x}" "$?"; declare -g "$1=${2%$'\n'}"; return $3; }
ov() { o v "$@"; }

case "$#:$1" in
(0:)		:;;
(*:-h|*:--help)	false;;
(1:-*)		OOPS branch cannot start with -: "$1";;
(1:*)		:;;
(*)		false;;
esac || i sed -n 's/^#U \?//p' "$0" >&2 || exit 42

branch="${1:-master}"

ov SHA git rev-parse --verify --quiet "$branch^{commit}"

ok=0
mis=0
new=0
spc=0
mod=0

# Find DIFFs to master (or given branch)
git diff -z --name-only "$SHA" |
while read -rd '' name
do
	if	[ ! -f "$name" ]
	then
		printf 'UNKNOWN: %q (in %q but not here)\n' "$name" "$branch"
		let mis++
		continue
	fi
	MIN=
	HIT=
	while	read -r sha
	do
		v THING git cat-file -p "$sha:$name" 2>/dev/null
#		echo -n "$sha."
		if	echo -n "$THING" | x cmp -s -- "$name" -
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
		printf 'NEWFILE: %q (nowhere in %q)\n' "$name" "$branch"
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

