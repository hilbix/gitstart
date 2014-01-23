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

set -e

OOPS()
{
echo "OOPS: $*"
exit 1
}

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

ignwarn=true	# should be false
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

edit()
{
vim "$(git show  --oneline --no-notes --name-only "$1" | sed 1d)"

# Missing here:
# We must commit the changes before we can do the cherry-pick.
# How can we - automagically - merge the edit and the future cherry-pick into a single commit?
# Perhaps the only way is to stick to the cherry pick standard process (or git rerere).
# However I like to resolve things first and then apply the merge/pick/etc. cleanly afterwards.
# To allow this is WIP.  Sorry.
}

# Ask if the SHA shall be applied as cherry-pick
: addpick SHA comment
addpick()
{
list=:
diff=:
help=false
while
	$list && lister "$list"
	$diff && sep "diff $1" git show "$1"
	{ $list && $diff; } || sep "file list" git show --oneline --no-notes --name-status "$1"
	list=false
	diff=false
	$help && echo && echo " try: Cherrypick Skip(once) Ignore(remember) Diff List Branches Vim eXit"
	help=false
	read -rsN1 -p"$* [csidlbvx]? " ans </dev/tty || exit
do
	echo "$ans"
	case "$ans" in
	c|C)	cherry "$1" && break;;
	s|S)	break;;
	i|I)	ignore "$1" "manually ignored"; break;;
	d|D)	diff=:;;
	l|L)	list=true;;
	b|B)	sep "branches" git branch -avv;;
	v|V)	edit;;
	x|X)	OOPS exit;;
	*)	help=:;;
	esac
done
}

# Process the cherry-pick
: cherry SHA
cherry()
{
if	git cherry-pick -x -Xpatience "$1"
then
	# Picking was successfull, check if path-ids match
	[ ".$(git show "$1" | git patch-id | cut -f1 -d' ')" = ".$(git show HEAD | git patch-id | cut -f1 -d' ')"  ] && return

	ignore "$1" "see $(git rev-parse HEAD)"
	return
fi
git status
git diff -b
git cherry-pick --abort
return 1
}

# Add some SHA to the .gitcarray file to ignore it in future
: ignore SHA comment
ignore()
{
echo "$1 `date +%Y%m%d-%H%M%S` ${*:2}" >> "$CARRY"
}

# Remove some SHA from the .gitcarray file
: remover SHA
remover()
{
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

warns=false
while	read -ru6 flg sha note
do
	case "$flg" in
	warn)	rmpick "$sha" "$note"; continue;;
	+)	addpick "$sha" "$note"; continue;;
	*)	OOPS "unkown flag: $flg";;
	esac
done 6< <(huntpicks)

