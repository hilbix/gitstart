#!/bin/bash
#
# Interactively do something like following not working pipe:
# git cherry HEAD $1 | git cherry-pick

SRC=GIT
CARRY=.gitcarry

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
lesser()
{
export LESS="-X -S -F -R"
expand | cut -b 1-$WIDTH |
$mode
}

sep()
{
echo '
------------------------------------------------------------------------
'
[ 0 = $# ] || "$@" | lesser
}

# Only list cherrypicks not yet ignored
huntpicks()
{
note "Checking $1...$2"
git cherry -v "$1" "$2" |
awk -v CARRY="$CARRY" '
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
			for (i=0; i<want; i++)
				print need[i];
			}
'
}

ignwarn=false
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
	b|B)	sep x git branch -avv;;
	d|D)	sep x git show "$2";;
	x|X)	OOPS exit;;
	i|I)	ignwarn=:; break;;
	*)	echo " try: Remove Keep Diff Branches eXit Quit Ignore";;
	esac
done
}

addpick()
{
list=:
diff=:
while
	$list && sep x git log -n 5 --reverse --oneline
	$list && sep x git log -n 5 --reverse --oneline "$ARG2"
	$list && sep x huntpicks "$ARG1" "$ARG2"
#	$list && sep x git cherry -v "$ARG1" "$ARG2"
	$diff && sep x git show "$1" | lesser
	list=false
	diff=false
	read -rsN1 -p"$* [csidlbx]? " ans </dev/tty || exit
do
	echo "$ans"
	case "$ans" in
	c|C)	cherry "$1" && break;;
	s|S)	break;;
	i|I)	ignore "$1" "manually ignored"; break;;
	d|D)	diff=:;;
	l|L)	list=:;;
	b|B)	sep x git branch -avv;;
	x|X)	OOPS exit;;
	*)	echo " try: Cherrypick Skip Ignore Diff List Branches eXit Quit";;
	esac
done
}

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

ignore()
{
echo "$1 `date +%Y%m%d-%H%M%S` ${*:2}" >> "$CARRY"
}

remover()
{
note REMOVE NOT YET IMPLEMENTED
return 1
}


ARG1="$(git rev-parse --abbrev-ref HEAD)"
case "$#:$1" in
0:)	ARG2="upstream/$ARG1";;
1:*..*)	ARG1="${1%%..*}""; ARG2="${1%%*..}"";;
1:*)	ARG2="$1";;
2)	ARG1="$1"; ARG2="$2";;
*)	OOPS "wrong number of arguments: $*";;
esac

warns=false
while	read -ru6 flg sha note
do
	case "$flg" in
	warn)	rmpick "$sha" "$note"; continue;;
	+)	addpick "$sha" "$note"; continue;;
	*)	OOPS "unkown flag: $flg";;
	esac
done 6< <(huntpicks "$ARG1" "$ARG2")


