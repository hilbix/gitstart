#!/bin/bash
#
# vim: ft=bash :
#
# Various git utils combined into one
#
# git util command args..
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

STDOUT() { local e=$?; printf %q "$1"; [ 1 -ge $# ] || printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { local e=$?; STDOUT "$@" >&2; return $e; }
OOPS() { STDERR OOPS: "$@"; exit 23; }
x() { "$@"; }
o() { x "$@" || OOPS fail $?: "$@"; }

case "$#" in
(0)	set -- help;;
esac

: [command]..
# give help for commands
cmd-help()
{
  local -A CMD HELP
  local max=0

  while read -ru6 line
  do
	case "$line" in
	(': '*)		A="${line#': '}"; B=;;
	('# '*)		B="$B"$'\t'"${line#'# '}"$'\n';;
	('cmd-'*'()')	C="${line#cmd-}";
			C="${C%'()'}";
			CMD["$C"]="$A";
			HELP["$C"]="$B";
			[ $max -ge "${#C}" ] || max="${#C}"
			;;
	esac
  done 6<"$0"
  if	[ 0 = "$#" ]
  then
	for a in "${!CMD[@]}"
	do
		printf '%-*q\t%s\n' "$max" "$a" "${CMD["$a"]}"
	done
	exit 42
  fi
  for a
  do
	[ -n "${CMD["$a"]}${HELP["$a"]}" ] || OOPS unknown command: "$a"
	printf '%-*q\t%s\n%s' "$max" "$a" "${CMD["$a"]}" "${HELP["$a"]}"
  done
  exit 42
}

: [configfile]..
# output the config a sorted way
cmd-configsort()
{
  [ 0 = $# ] && set -- "$(git rev-parse --git-dir)/config"
  awk '
/^\[.*\]$/	{ section=$0; next; }
		{ print section "\t" $0 }
      ' "$@" |
  sort |
  awk -F'\t' '
  $1 != last	{ print $1; last=$1 }
		{ sub(/^[^\t]*\t/,""); print }
             '
}

declare -f "cmd-$1" >/dev/null 2>&1 || OOPS unknown subcommand "$1"
cmd-"$1" "${@:2}"

