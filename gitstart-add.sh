#!/bin/bash
#
# ARG1	reponame, give as '' for autodetection
# ARG2	remoteaccount, give as 'name' for github.com, else host:name

export LC_ALL=C

ARG1="$1"
ARG2="$2"

HERE="$(readlink -e .)"

SSHDIR="$HOME/.ssh"
DIR="$SSHDIR/git"
OLD="$SSHDIR/old"
CONF="$SSHDIR/config"

mkdir -p "$DIR" "$OLD"

usage()
{
cat <<EOF >&2

Usage: $(basename -- "$0") ['${GITREPO:-GITREPO}' ['${GITACCOUNT:-GITACCOUNT}']]"
	Creates an SSH key named ${GITACCOUNT:-GITACCOUNT}-${GITREPO:-GITREPO}
	for use as an GIT Deployment Key.  When called the first time, you must give
	the 2nd parameter HOST:GITACCOUNT (like github.com:ACC when https://github.com/ACC).
	When called from a GIT directory, the first parameter defaults to the directory name.
	("some.wiki" and "some.git" are mixed with repo "some".  To force the name, add ".git":
	 "some.wiki" becomes "some.wiki.git" and "some.git" becomes "some.git.git")

EOF
exit 42
}

repo()
{
local r tmp

TOP="$(git rev-parse --show-toplevel)" ||
{
	cat <<EOF >&2
You are not in a git repository.  Please run:
	git init
EOF
	exit 1
}

TOP="$(readlink -e "$TOP")"

tmp="$TOP"
r="$TOP"
while	g="${tmp%[_A-Z]}"
	[ ".$g" != ".$tmp" ]
do
	case "$tmp" in
	(*_)	r="$g";;
	esac
	tmp="$g"
done
tmp="${r##*/}"
case "$tmp" in
({tmp,dev,stage,prod,work,maint}.*)	tmp="${tmp#*.}";;
esac

GITREPO="${ARG1:-$tmp}"
}

migrate()
{
if	[ -s "$SSHDIR/.github-default" ]
then
	cat <<EOF >&2

========================================================================
Note that this is intermediate until I come around to replace this with
something better.  Sorry for the disturbance.
========================================================================
It appears that you have used a previous version of
	$0
before.  Please note that several things are improved:

- Now new SSH keys  go into ~/.ssh/git/ to hide them from gnome-keyring.
- support other GIT services than GitHub
  For this the 2nd arg now looks like hostname:repo
- Now it is assumed, that the base URL uses https.
  http is insecure, so it is no more supported
- Now it is assumed, that the push always goes via SSH.
  (This supports at least GitHub and GitLab.)
- No need to rewrite the URL of origin anymore.  Instead it is done by:
  config --global url.NEW.insteadOf URL-of-origin

As a benefit your ~/.ssh/ can be kept a bit more tidy now.

To finish porting all the keys, do:

- For all repos, call this script inside to copy the ssh keys.
- Follow the instructions.
- Remove the old entries from "$CONF" manually
- Remove the old (ported) key, you can see it on link count >1
- Remove the old "$CONF.last*" entries if you like

After cleanup remove "$SSHDIR/.github-default" to get rid of this message.
========================================================================
EOF
	[ -s "$DIR/.git-default" ] ||
	cp --backup=t "$SSHDIR/.github-default" "$DIR/.git-default"
fi
}

account()
{
local def=

[ -s "$DIR/.git-default" ] && read def < "$DIR/.git-default"
GITACCOUNT="${ARG2:-$def}"

[ -z "$GITACCOUNT" -o -z "$GITREPO" ] && return 1

#settings#
case "$GITACCOUNT" in
(*[!-_./:a-zA-Z0-9]*)	printf 'OOPS: unclear character in %q\n' "$GITACCOUNT" >&2; exit 1;;
(*:*)			;;
(*)			GITACCOUNT="github.com:$GITACCOUNT";;	# GitHub is a bit preferred here
esac
echo "$GITACCOUNT" > "$DIR/.git-default"

NOWIKI="${GITREPO%.wiki}"
NOWIKI="${NOWIKI%.git}"

# In sanely done remotes, *.wiki URLs use the same connection as their main repos.
# (Not supported is to create some.wiki?  add a .git which then would have a some.wiki.wiki)
GITNAME="${GITACCOUNT//[:\/]/+}-$NOWIKI"
OLDNAME="${GITACCOUNT#*:}-$GITREPO"
}

check()
{
if	! ORG="$(git config --get remote.origin.url)" ||	# usually true
	[ -z "$ORG" ]						# usually never blank
then
	cat <<EOF >&2
Please add remote 'origin' first.  Like:
	git remote add origin https://${GITACCOUNT/://}/$GITREPO.git
Then rerun this here again:
	$0 $*
EOF
	exit 1
fi

if	[ -z "$ARG1" ] && [ ".${GITREPO##*/}" != ".$(basename "$ORG" .git)" ]
then
	cat <<EOF >&2
Please give the right name on commandline as first argument.  Autodetection gives
	$GITNAME
while current setting gives
	$ORG
This does not match.  For safety the script stops here.
EOF
	exit 1
fi
}

mkkey()
{
[ ! -s "$DIR/$GITNAME" ] &&
if [ -s "$SSHDIR/$OLDNAME" ]
then
	printf 'Porting %q to %q\n' "$OLDNAME" "$GITNAME"
	# Port old format to new one
	ln -v "$SSHDIR/$OLDNAME"     "$DIR/$GITNAME" &&
	ln -v "$SSHDIR/$OLDNAME".pub "$DIR/$GITNAME".pub
	# To really move it we would need to remove old clutter from ~/.ssh/config, no way, sorry
else
	ssh-keygen -qt ed25519 -C "$GITNAME" -f "$DIR/$GITNAME" -N '' </dev/null
fi
}

mkconf()
{
cat <<EOF >> "$CONF"

Host git-$GITNAME
 Hostname ${GITACCOUNT%%:*}
 User git
 IdentityFile $DIR/$GITNAME
 IdentitiesOnly yes
 IdentityAgent none

EOF
}

showkey()
{
cat - "$DIR/$GITNAME.pub" <<EOF

Add this (writable) Deployment Key to https://${GITACCOUNT/://}/$GITREPO/settings/keys

EOF
echo
[ ".$TOP" = ".$HERE" ] ||
cat <<EOF >&2
+-----------------------------------------------------------------------
! WARNING!
! You are not in the git top level git directory.  The git top level is:
! $TOP
+-----------------------------------------------------------------------

EOF
}

backup()
{
[ ! -s "$1" ] || cmp -s "$1" "$OLD/${1##*/}" || cp --backup=t "$1" "$OLD/${1##*/}"
}

create()
{
local line="Host git-$GITNAME"

# Always keep some backup of the ssh config, it cannot hurt.
backup "$CONF"

if [ -d "$CONF.d" ]
then
	fgrep -qx "$line" "$CONF" &&
	printf '

Consider to manually remove section
	%s
from	%q

' "$line" "$CONF" >&2

	CONF="$CONF.d/$GITNAME.conf"
	backup "$CONF"
	mkkey
	#
	# NEW: mkconf in ~/.ssh/config.d/ iff it does not yet exist (also: migrate)
	#
	[ ! -s "$CONF" ]
else
	printf '

Consider to

	mkdir %q.d && echo Include %q.d/\\*.conf >> %q

' "$CONF" "$CONF" "$CONF" >&2

	#
	# OLD: mkconf in ~/.ssh/config if mkkey runs
	#

	mkkey
fi &&
mkconf
}

finish()
{
# Suppress if everything already is set up correctly
org="$(git ls-remote --get-url origin)"
[ ".$org" = ".git-$GITNAME:${GITACCOUNT#*:}/$GITREPO.git" ] && return

echo "Please do:"

[ ".$ORG" = ".$org" ] ||
cat <<EOF

git config --global --unset 'url.$org.insteadOf';
EOF

cat <<EOF

git fetch https://${GITACCOUNT/://}/empty.git;
git tag empty FETCH_HEAD;
git reset --soft FETCH_HEAD;

git config --global 'url.git-$GITNAME:${GITACCOUNT#*:}/$GITREPO.git.insteadOf' '$ORG';
git push -u origin master;

If your git is too old for the last command, use this sequence instead:
git push origin master; git checkout origin/master;
git branch -f master origin/master; git checkout master

To display this information again, run this here as often as you like:
$0 $*

EOF
}

#
# Some easy steps to Walhall
#

repo
migrate
account || usage
check
create
showkey
finish

