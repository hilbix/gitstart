#!/bin/bash
#
# Add all forks of a GH repository as remote
# The remotes are named such, that they sort last.
#
# WTF gh --paginate?!?
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

CACHED="$(which unbuffered md5sum >/dev/null 2>&1 && which cached.sh)"
[ -n "$CACHED" ] || printf 'Running uncached\n' >&2

STDOUT() { printf %q "$1"; [ 1 -ge $# ] || printf ' %q' "${@:2}"; printf '\n'; }
STDERR() { local e=$?; STDOUT "$@" >&2; return $e; }
DEBUG()	{ local e=$?; [ -z "$DEBUG" ] || STDERR "$@"; return $e; }
x() { DEBUG exec: "$@"; "$@"; DEBUG rc=$?: "$@"; }

# Escape any string into ASCII only using
# A-Za-z0-9_-
toascii()
{
  a="$1"
  c=
#  LC_ALL=C	the code below properly handes UTF-8
  while	[ 0 -lt "${#a}" ]
  do
	c="${a:0:1}"
	a="${a:1}"
	case "$c" in
	([a-zA-Z0-9-])	;;
	(_)		c=__;;
	(/)		c=_-_;;
	(*)		printf -vc '_%x_' "'$c";;
	esac
	printf %s "$c"
  done
}

map() { while read -r a; do "$@" "$a"; done; }

list-remotes() { x git remote; }
get-remote-url() { x git config --get "remote.$1.url"; }
filter-github-urls()
{
  DEBUG filter-github-urls "$1"
  case "$1" in
  (https://github.com/*)	echo "${1#https://github.com/}";;
  (git@github.com:*)		echo "${1#git@github.com:}";;
  esac
}
clr="$(tput el)"
clr()
{
  {
  printf '\r'
  [ 0 = $# ] || printf '%q ' "$@"
  printf '%s' "$clr"
  } >&2
}
gh-repo-source-fullname()
{
  clr repo "$1"
  case "$1" in
  (*/*/*)	clr; STDERR ignored: "$1"; return;;
  (*/*.git)	;;
  (*)		clr; STDERR does not end on .git: "$1"; return;;
  esac;
  data="$(x $CACHED gh api "repos/${1%.git}")" || return
  x jq -r '.source.full_name // .full_name' <<<"$data"
  x jq -r '.parent.full_name // .full_name' <<<"$data"
  x jq -r '.full_name' <<<"$data"
}
gh-repo-forks()
{
  clr forks of "$1"
  x $CACHED gh api --paginate "repos/$1/forks" | jq -r '.[].full_name'
} 
remote-name()
{
  # the idea is that UTF-8 0x100000 is f4 80 80 80
  # and hopefully sorts after everything else you might use
  # (even if you use characters from higher unicode code panes)
  printf -v "$1" '\U100000gh/%s' "$(toascii "$2")"
}
add-remote-fork()
{
  remote-name name "$1"
  x git remote get-url "$name" >/dev/null 2>/dev/null && return
  printf 'add %q\n' "$1"
  x git remote add "$name" "https://github.com/$1.git"
#  git remote set-url	"github-$name" "https://github.com/$1.git"
}

export LC_ALL=C.UTF-8

list-remotes |
map get-remote-url |
map filter-github-urls |
map gh-repo-source-fullname |
sort -u |
map gh-repo-forks |
map add-remote-fork

clr

