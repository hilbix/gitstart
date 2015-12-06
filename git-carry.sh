#!/bin/bash
#
# Do something like following with a bit more interactive control:
# git cherry HEAD $1 | git cherry-pick --stdin
#
# This remembers states in a directory called .gitcarry
# This must be run in the topmost git directory like with:
#	git config --global alias.carry '!git-carry.sh'

SRC=GIT
DIR=.gitcarry

MINBASH=3.1
MINGIT=1.7.10

export LC_ALL=C

set -e

OOPS()
{
echo "OOPS: $*"
exit 1
}

expr "$MINBASH" '>' "$BASH_VERSION" >/dev/null && OOPS "this needs bash $MINBASH or above"
expr "$MINGIT" '>' "$(git version | sed 's/^[^0-9]*//g')" >/dev/null && OOPS "this needs GIT $MINGIT or above"

note()
{
echo "$*" >&2
}

x()
{
case "$1" in
cd)	"$@" && echo && echo "Entering: $2";;
*)	( "$@"; );;
esac || OOPS "$@"
}

i()
{
( "$@"; ) || :
}

mode=less
WIDTH="`tput cols`" || mode=cat
note WIDTH=$WIDTH

# fix LESS such that -S does not break -F
: lesser
lesser()
{
export LESS="-X -S -F -R"
expand | cut -b "1-$WIDTH" |
$mode
}

: sep command
sep()
{
m=$[${#1}/2]
p="------------------------------"
p="-----${p:$m}"

echo "
$p $1 $p
"
x "${@:2}" | lesser
}

# Only list cherrypicks not yet ignored
: huntpicks
huntpicks()
{
note '################ Remember to "git remote update --prune" ################'
note "$CARRY checking $ARG1...$ARG2"
git cherry -v "$ARG1" "$ARG2" |
awk -v CARRY="$CARRY" -v FULL="$1" '
BEGIN			{
			while ((getline < CARRY)>0)
				if (!/^[[:space:]]*$/ && ! /^[[:space:]]*#/)
					nocarry[$1]=$0;
			want=0;
			}

/^[[:space:]]*$/	{ next; }
$1=="-"			{ next; }
nocarry[$2]		{ had[$2]=1; next; }
			{ need[want++]=$0; }
END			{
			for (a in nocarry)
				if (nocarry[a]!="" && !had[a])
					print "warn missing " nocarry[a];
			for (i=0; i<want && ( FULL=="true" || i<10 ); i++)
				print need[i];
			if (i<want)
				print "[" (want-i) " more entries skipped]"
			}
'
}

ignwarn=false
ignwarn=true	# XXX TODO: REMOVE THIS LINE
# Ask if souperfluous SHA shall be removed from .gitcarry
: rmpick text SHA comment
rmpick()
{
$ignwarn && { echo "[$ARG1...$ARG2] $*"; return; }
while
	read -rsN1 -p"[$ARG1...$ARG2] $* [rkdbxi]? " ans </dev/tty || exit
do
	echo "$ans"
	case "$ans" in
	r|R)	remover "$2";; # Remover here
	k|K)	return;;
	b|B)	sep "branches" git branch -avv;;
	d|D)	sep "diff $2" git show "$2";;
	x|X)	OOPS exit;;
	i|I)	ignwarn=:; break;;
	*)	echo " try: Remove Keep Diff Branches eXit Quit Ignore";;
	esac
done
}

lister()
{
{
sep "$ARG1" git log -n 5 --reverse --oneline "$ARG1"
sep "$ARG2" git log -n 5 --reverse --oneline "$ARG2"
sep "all picks" huntpicks "$1"
} | lesser
}

: filelist CMD ARGS..
filelist()
{
# This is one major shell drawback:
# Handling lists of files possibly containing whitespace themself.
# We fix that by reading in lines (assuming filenames never contain LF)
# and record them in an array.  This is a bash feature.
FILELIST=()
while read -ru8 name
do
	FILELIST+=("$name")
done 8< <("$@")

}

edit()
{
filelist "${@:2}"
vim $1 "${FILELIST[@]}"
}

ed()
{
# editor has no standard way to search across all variants, sorry
filelist "$@"
editor "${FILELIST[@]}"
}

pickfiles()
{
git show  --oneline --no-notes --name-only "$1" | sed 1d
}

SKIPS=""
# Ask if the SHA shall be applied as cherry-pick
: addpick SHA comment
addpick()
{
[ -n "$next" ] || { read -r flg sha note < <(huntpicks | grep ^+ | fgrep -vxf <(echo "$SKIPS")); next="$flg $sha"; note "next: $next"; }
[ "+ $1" = "$next" ] || { note "skipping $1 $2"; return; }
next=""

list=:
diff=:
help=false
while
	$list && lister "$list"
	$diff && sep "diff $1" git show "$1"
	{ $list && $diff; } || sep "file list" git show --oneline --no-notes --name-status "$1"
	list=false
	diff=false
	$help && echo && echo " try: Cherrypick Skip(once) Ignore(remember) Diff List Branches Vim/Edit eXit"
	help=false
	read -rsN1 -p"$* [csidlbvex]? " ans </dev/tty || exit
do
	echo "$ans"
	case "$ans" in
	c|C)	cherry "$1" && break;;
	s|S)	SKIPS="$SKIPS+ $*
"; break;;
	i|I)	ignore "$1" "manually ignored"; break;;
	d|D)	diff=:;;
	l|L)	list=true;;
	b|B)	sep "branches" git branch -avv;;
	v|V)	edit '' pickfiles "$1";;
	e|E)	ed pickfiles "$1";;
	x|X)	OOPS exit;;
	*)	help=:;;
	esac
done
}

: diff-combined
diff-combined()
{
# When `git diff --cc` is empty, then append `git diff -c` as well, else it is too confusing ;)

combined="$(git diff -b -c)"
condensed="$(git diff -b --cc)"
[ ".$condensed" = ".${combined/--combined/--cc}" ] || echo "$combined

=== condensed follows: =================================================
"
echo "$condensed"
}

statusfiles()
{
git status --porcelain | sed s/^...//
}

fixcherry()
{
filelist "$@"
for a in "${FILELIST[@]}"
do
	git diff -b "$a" | grep '^++<<<<<<' && { note "$a still has unresolved conflicts"; return 1; }
	git add "$a"
done
git diff -b -c | grep '^++<<<<<<' && { note "WTF? There are still some unresolved conflicts?"; return 1; }
git cherry-pick --continue
}

: resolve pick
resolve()
{
diff=:
while
	sep "pick conflicts" git status
	$diff && sep "diff $1" diff-combined
	diff=false
	$help && echo && echo " try: Diff Vim/Edit Continue Undo(Abort) eXit"
	help=false
	read -rsN1 -p"$* [dvecuax]? " ans </dev/tty || exit
do
	echo "$ans"
	case "$ans" in
	d|D)	diff=:;;
	v|V)	edit '+/<<<<<<<' statusfiles; diff=:;;
	e|E)	ed statusfiles; diff=:;;
	c|C)	fixcherry statusfiles && return; diff=:;;
	u|U)	git cherry-pick --abort; return 1;;
	a|A)	git cherry-pick --abort; return 1;;
	x|X)	OOPS exit;;
	*)	help=:;;
	esac
done
}

# Process the cherry-pick
: cherry SHA
cherry()
{
git merge --ff-only "$1" || git cherry-pick -x -Xpatience "$1" || resolve "$1" || return

# Picking was successful, check if path-ids match
[ ".$(git show "$1" | git patch-id | cut -f1 -d' ')" = ".$(git show HEAD | git patch-id | cut -f1 -d' ')"  ] && return

ignore "$1" "see $(git rev-parse HEAD)"
}

# Add some SHA to the .gitcarray file to ignore it in future
: ignore SHA comment
ignore()
{
echo "$1 `date +%Y%m%d-%H%M%S` ${*:2}" >> "$CARRY"
git commit -m "updated $CARRY" "$CARRY"
}

# Remove some SHA from the .gitcarray file
: remover SHA
remover()
{
# XXX TODO IMPLEMENT THIS
note REMOVE NOT YET IMPLEMENTED
return 1
}

# Look into .gitcarry/ to find suitable .default file.
# If not found, stick to the defaults.
: locate-default /branch ''
locate-default()
{
if [ -f "$DIR/$1/.default" ]
then
	read ARG2 < "$DIR/$1/.default"
	# If something like .../ then append the rest, else it is an absolute destination
	case "$ARG2" in
	*/)	ARG2="$ARG2${2#/}";;
	esac
	return
fi

[ -z "$1" ] && return

# Tail recoursion
locate-default "${1%/*}" "/${1##*/}$2"
}

# Set the default values

ARG1="$(git rev-parse --symbolic-full-name HEAD)"
ARG1="${ARG1#refs/heads/}"
ARG2="upstream/$ARG1"

# Pick some sane command line arguments

case "$#:$1" in
0:)	locate-default "/$ARG1";;
1:*..*)	ARG1="${1%%..*}""; ARG2="${1%%*..}"";;
1:*)	ARG2="$1";;
2)	ARG1="$1"; ARG2="$2";;
*)	OOPS "wrong number of arguments: $*";;
esac

# Recalculate sane values

ARG1="$(git rev-parse --symbolic-full-name "$ARG1")"
ARG1="${ARG1#refs/heads/}"
ARG2="$(git rev-parse --symbolic-full-name "$ARG2")"
ARG2="${ARG2#refs/}"

# Prepare the correct .gitcarry-file

CARRY="$DIR/$ARG1/$ARG2"
mkdir -p "${CARRY%/*}"

# Run all the possible picks displayed by "git cherry"

next=
warns=false
while	read -ru6 flg sha note
do
	case "$flg" in
	warn)	rmpick "$sha" "$note"; continue;;
	+)	addpick "$sha" "$note"; continue;;
	*)	OOPS "unkown flag: $flg";;
	esac
done 6< <(huntpicks true)

# See TODO above
