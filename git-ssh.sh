#!/bin/bash
#
# Manage git SSH keys
# This manages SSH connect keys of the form
#	$DIR/$KEY$SITE$SEP$ACCOUNT$SEP$REPO:$PREFIX$ACCOUNT$MID$REPO$SUFFIX
# and creates suitable SSH entries in
#	$DIR/$CONFIG
# To activate:
#	git config --global --add alias.ssh git-ssh.sh
#
# args: [options] cmd [args]
#
# options are:
#	site=NAME
#		NAME another site to operate on, default see "set default".
#
# cmd:
#	set key value
#	get key
#	show
#	add [repo]
#	help
#
# key:
#	default SITE
#		set the default SITE
#	host HOST
#		set the host to connect to
#	port PORT
#		SSH port, default '' (left away, so it's 22)
#	user USER
#		SSH user, default 'git'
#	prefix STRING
#		set the prefix STRING, default ''
#	account ACCOUNT
#		set the site's ACCOUNT
#	mid STRING
#		set the mid STRING, default '/'
#	suffix STRING
#		set the suffix STRING, default ''
#	dir DIR
#		set the SSH directory, default "$HOME/.ssh"
#	config CONFIG
#		set the config file name, default "config"
#	key KEY
#		set the key prefix, default "git-"
#	sep SEP
#		separator in the key, default "-"
#
# Example GitHub (this already is predefined):
#
# git ssh site=github set host github.com
# git ssh site=github set port ''
# git ssh site=github set user git
# git ssh site=github set prefix ''
# git ssh site=github set account MyAccountName
# git ssh site=github set mid /
# git ssh site=github set suffix .git
# git ssh default github
#
# By setting default in advance, this can be changed to:
#
# git ssh default github
# git ssh set host github.com
# git ssh set port ''
# git ssh set user git
# git ssh set prefix ''
# git ssh set account MyAccountName
# git ssh set mid /
# git ssh set suffix .git
#
# You can alias this easily: 
#
# git config --global --add alias.github "ssh site=github"

while :
do
	case "$1" in
	*=*)	option "$1"; shift; continue;;
	set)	setter "$@"; break;;
	*)	OOPS "unknown command: '$1'";;
	esac
esac

def=
[ -d .git -a -f .git/config ] && def="`/bin/pwd`"
def="`basename "$def"`"
GITHUBREPO="${1:-$def}"
while	g="${GITHUBREPO%[-._A-Z]}"
	[ ".$g" != ".$GITHUBREPO" ]
do
	GITHUBREPO="$g"
done

def=
read def < "$DIR/.github-default"
GITHUBACCOUNT="${2:-$def}"
if [ -z "$GITHUBACCOUNT" -o -z "$GITHUBREPO" ]
then
	cat >&2 <<EOF
Usage: `basename "$0"` ['${GITHUBREPO:-GITHUBREPO}' ['${GITHUBACCOUNT:-GITHUBACCOUNT}']]"
	Creates an SSH key named ${GITHUBACCOUNT:-GITHUBACCOUNT}-${GITHUBREPO:-GITHUBREPO}
	for use as an GITHUB Deployment Key.  When called the first time, you must give
	the 2nd parameter (GITHUBACCOUNT from https://github.com/GITHUBACCOUNT).
	When called from a GIT directory, the first parameter defaults to the directory name.
EOF
	exit 1
fi

echo "$GITHUBACCOUNT" > "$DIR/.github-default"

GITNAME="$GITHUBACCOUNT-$GITHUBREPO"

[ ! -f "$DIR/$GITNAME" ] &&

ssh-keygen -qt rsa -C "$GITNAME" -f "$DIR/$GITNAME" -N '' </dev/null &&

{
cmp -s "$DIR/config" "$DIR/config.last" && rm -f "$DIR/config.last";

cat <<EOF >> "$DIR/config"

Host git-$GITNAME
 Hostname github.com
 User git
 IdentityFile $DIR/$GITNAME

EOF
}

cp --backup=t "$DIR/config" "$DIR/config.last" &&

cat <<EOF

Paste this to GitHub:

EOF

cat "$DIR/$GITNAME.pub" - <<EOF

To make your local master branch tracking the remote master branch
(this assumes you have committed everything):

git remote rename origin oldorigin
git remote add origin git-$GITNAME:$GITHUBACCOUNT/$GITHUBREPO.git
git push origin master ### THIS ONE IS IMPORTANT ###
git checkout origin/master; git branch -f master origin/master; git checkout master

To display this information again, just run $0 again.

EOF
