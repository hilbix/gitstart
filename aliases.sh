#!/bin/bash

export LC_ALL=C.UTF-8 || export LC_ALL=C

q() { sed "s/'/'\\\\''/g"; }
s() { git config --global --replace-all "$1" "${*:2}"; }
a() { s "alias.$@"; }
# bash wrapper
b() { a "$1" "!LC_ALL=$LC_ALL bash -c  '$(q)' --"; }
x() { a "$1" "!LC_ALL=$LC_ALL bash -xc '$(q)' --"; }

a alias	!git-alias.sh
a amend	commit --amend
a amit	commit --amend -C HEAD
a bvv	branch -avv
b bv.ign <<<'for a; do git config --local --get-all ignore.bv | fgrep -qx "$a" || git config --local --add ignore.bv "$a"; done'
b bv	<<'EOF'
for a; do git config --local --unset ignore.bv "$a"; done;
{
git config --get-all ignore.bv | sed 's/^/d/';
git branch -avv | sed 's/^/x/';
} |
awk '
/^d/							{ a=substr($0,2); ign[a]=1; b=a; sub(/[^/]*$/,"",b); c=substr($0,2+length(b)); if (b=="") b="(local)"; m[b]="ignored"; f[b]="branch:"; k[b]=k[b] " " c; next }
$2=="(detached" && $3=="from" && $4==$5")"		{ $2="HEAD"; $3=$5; }
$2=="(HEAD" && $3=="detached" && $4=="at" && $5==$6")"	{ $2="HEAD"; $3=$6; }
$3!="->"	{
		m[$3]=m[$3] substr($1,2);
		sub(/^remotes\//,"/",$2);
		if (ign[$2]) next;
		if (!f[$3])
			{
			f[$3]=$2;
			if (length($2)>mx) mx=length($2);
			}
		else	{
			l=length($2)-length(f[$3]);
			if (substr($2,l)=="/"f[$3]) $2=substr($2,1,l);
			k[$3]=k[$3] " " $2;
			}
		}
END	{
	for (a in f)
		printf("x%-1s %s %-*s %s\n", m[a], a, (length(m[a])<2 ? mx : 0), f[a], substr(k[a],2));
	}' |
sort -bk2 |
sed 's/^x//'
EOF
# Same for tags
a tv	"!{ git tag --no-column | while read -r tag; do echo \"\$(git rev-parse \"refs/tags/\$tag\" || echo .)	\$tag\"; done; git remote | while read -r n; do echo -n \":: \$n\" >&2; git ls-remote --tags \"\$n\" | grep -vG '\\^{}\$' | awk -F'\\t' -vN=\"\$n\" '{ sub(/^[^/]*\/[^/]*/,\"\",\$2); print \$1 \"\\t/\" N \$2 }'; done; echo >&2; } | sort -r | awk '{ if (!f[\$1]) { f[\$1]=\$2; if (mx<length(\$2)) mx=length(\$2); } else { l=length(\$2)-length(f[\$1]); if (\"/\"f[\$1]!=substr(\$2,l)) l=length(\$2); m[\$1]=m[\$1] \" \" substr(\$2,0,l); } } END { for (a in f) printf(\"%s %-*s %s\\n\", a, mx, f[a], m[a]); }' | sort"
a check	diff --check
b contained	<<<'[ -n "$(git branch --list --contains "${*-HEAD}" 2>/dev/null | sed -e "s/^..//" -e "/^(/d")" ] && exit; printf "FAIL: %q is not on a branch\\n" "${*-HEAD}" >&2; exit 1'
a co	'!git contained && git checkout'
a ff	merge --ff-only --
a pager	'!pager() { cd "$GIT_PREFIX" && git -c color.status=always -c color.ui=always "$@" 2>&1 | less -XFR; }; pager'
a pageat '!pager() { at="$1" && shift && cd "$GIT_PREFIX" && git -c color.status=always -c color.ui=always "$@"  2>&1 | less -XFRp "$at"; }; pager'
a tree	'!cd "$GIT_PREFIX" && git pager log --color=always --graph --oneline --decorate --all'
a ls	'!cd "$GIT_PREFIX" && git pager log --color=always --graph --oneline --decorate'
a ll	'!cd "$GIT_PREFIX" && git pager log --color=always --graph --oneline --decorate --numstat'
a la	'!cd "$GIT_PREFIX" && git pager log --color=always --graph -u --decorate'
a st	'!cd "$GIT_PREFIX" && git pager status'
a ss	'!cd "$GIT_PREFIX" && git pager submodule summary'
# not easy to pass additional parameters to subnodule foreach, when you need '$toplevel' etc.
# git su: update all
# git su path: update only this path
# git su path/: update all in this path, not this path
# git su -r: update all recursively
# git su -r path: update only path
b su <<'su-EOF'
cd "$GIT_PREFIX" || exit;
args='';
[ 0 = $# ] || printf -vargs " %q" "$@";
git pager submodule foreach 'git sane-submodule-update-from-submodule-foreach "$toplevel" "$path" "$name" "$sha1"'"$args"
su-EOF
# 'git submodule update' is insane, as it just cuts the current leaf of the submodule,
# regardless if it gets lost or not.
# This one here hopefully is sane in the sense that it only allows FF updating.
b sane-submodule-update-from-submodule-foreach	<<'EOF'
top="$1";
pat="$2";
nam="$3";
sha="$4";
shift 4 || exit;
args=();
recurse=false;
case "$1" in
-r*|--r*)	args=(--recursive); recurse=:; shift;;	# I am lazy
esac;
case "$1" in
--)		shift;;			# Do not harm others with my laziness.
esac;
[ 0 = $# ] && set -- '';

# Move this here to given $sha
update()
{
# check if it is dirty, if so, do not change (as we are editing)
ok="$(git status --porcelain)" && [ -z "$ok" ] || { printf '\n# Not clean!\n# MODULE %q\nPATH %q\n' "$pat" "$top" >&2; exit 1; };
# first try some ff to the given SHA
was="$(git rev-parse HEAD)";
[ ".$was" = ".$sha" ] && printf 'ok %q\n' "$sha";
git ff "$sha" >/dev/null;
at="$(git rev-parse HEAD)";
[ ".$at" = ".$was" ] || { printf 'fast forward %q..%q\n' "$was" "$at"; };
[ ".$at" = ".$sha" ] ||
if	# We are not at the wanted SHA, looks like it moves backward.
	git contained "$at";
then
	# sha is contained in some branch, so we can safely move downward
	git checkout --detach;
	git reset --hard "$sha";
	[ ".$sha" = ".$(git merge-base "$sha" "$at")" ] && act="moved backward" || act=jumped;
	printf '%s from %q\n%s to   %q\n' "$act" "$at" "$act" "$sha";
fi;
$recurse && exec git su "${args[@]}";	# all is done, so we need not return
};

subpath()
{
sub="${1#"$2"}";
case "$sub" in
('')	return 0;
("$1")	;;
('/'*)	return 0;
esac;
false;
};

ishit() { local a; for a; do [ -z "$a" ] || subpath "$pat" "${a%/}" && return; done; false; };

ishit "$@" && update;

subs=();
for a; do subpath "$a" "$pat" && [ -n "$sub" ] && subs+="${sub#/}"; done;
[ 0 = ${#subs[@]} ] && exit;

#printf '## %q\n' "${subs[@]}";
git su "${args[@]}" -- "${subs[@]}";
:;
EOF
a up	status
a squash	rebase --interactive
a fixup		rebase --interactive --autosquash

#a fastforward # git fetch; git fastforward -> ff all branches which can do so, flag which cannot

# see https://stackoverflow.com/a/23532519
a amend-tag	'!f(){ [ 1 = $# ] || { echo "amend-tag needs tag name"; return 1; }; git tag -f -a -- "$1" "$1^{}"; }; f'

# see https://stackoverflow.com/a/30286468
b find <<'find-EOF'
ARGS=;
for a in "${@-.}"; do ARGS="$ARGS)|($a"; done;
git log -C -M -B --pretty=format:$'\t'%h --name-status --all |
awk -vP="(${ARGS:3})" '
/^[\t]/	{ sha=$1; next }
$0 ~ P	{ print sha "\t" $0; ret=1 }
END	{ exit 1-ret }'
find-EOF
b qf <<'qf-EOF'
cd "$GIT_DIR";
x="$(find objects -type f | sort | md5sum)";
cmp -s quickfind.status.tmp <<<"$x" ||
{
echo -n "indexing .." >&2;
git log -C -M -B --pretty=format: --name-status --all | sort -k2 | sed '/^$/d' | uniq -c > quickfind.list.tmp && echo "$x" > quickfind.status.tmp;
echo " done" >&2;
};
egrep "${@:-.}" < quickfind.list.tmp;
qf-EOF
# find SHAs of exact commit messages
b exact <<'exact-EOF'
# This format hopefully never changes
git log --raw "${@:2}" |

# Converts the log into some NUL terminated lines
# Lines starting with a TAB are SHAs
# as git commit messages never start with a TAB.
awk '
/^$/		{ printf "%c", 0; next }
/^commit /	{ printf "\t%s", $2 }
/^    /		{ sub(/^    /,""); print }' |

# Now search for the exact commit message
awk -vA="$1"$'\n' '
BEGIN	{ RS=sprintf("%c",0) }
/^[\t]/	{ sha=$1; next }
$0==A	{ print sha; ret=1 }
END	{ exit 1-ret }'
exact-EOF

# See https://stackoverflow.com/a/44973360
b sdiff	<<'EOF'
O=();
A=();
while	x="$1";
	shift;
do
	case $x in
	-*)	O+=("$x");;
	*)	A+=("$x^{}");;
	esac;
done;
g()
{
git show "${A[$1]}" && return;
echo FAIL ${A[$1]};
git show "${A[$2]}";
};
diff "${O[@]}" <(g 0 1) <(g 1 0)
EOF
a udiff	'!git sdiff -u'
a bdiff	'!git sdiff -b'
a ddiff	'!git pager udiff'
# Hightlight differences in blanks.  Solves: `git diff -b` is clean while `git diff` is not
a cdiff	'!cdiff() { git diff --color "$@" | perl /usr/share/doc/git/contrib/diff-highlight/diff-highlight | less -XFR; }; cdiff'

# Register all submodules which are missing in the index.
# Why isn't there an option to `submodule init` for this?
b submodules-register <<'EOF'
# Safely extract the submodule keys.  You must use -z, as following cannot be parsed line by line:
#	git submodule add . xxx && git mv xxx $'.\nsubmodule.fake.path err\n'
# It's good to always test with filenames which end on $'\n' and also contain some fakey expected lines.
# Luckily, keys cannot contain $'\n' nor NUL.  For example, following shows, this is unsupported (exposes a git bug?):
#	git submodule add URL $'a\nb'
git config -f .gitmodules -z --get-regexp '^submodule\..*\.path$' |
sed -z 's/\n.*$//' | tr '\0' '\n' |
while read -r key;
do
	sub="${key%.path}";
	pth="$(git config -f .gitmodules --get "$sub.path")x" &&
	url="$(git config -f .gitmodules --get "$sub.url")" &&
	if	pth="${pth%x};	# protects against filenames with trailing $'\n'
		bra="$(git config -f .gitmodules --get "$sub.branch")" &&
		[ -n "$bra" ];
	then
		git submodule add -b "$bra" -- "$url" "$pth";
	else
		git submodule add -- "$url" "$pth";
	fi;
done
EOF

# Do a fake merge with the given refs.
# Parent is the current HEAD.
# Content is the current index.  Use git read-tree etc. to set etc.
# You can use the usual environment stuff to augment the commit.
# If you need more, use 'git commit --amend'
#
# I did not find out how to have git tell what an argument is (sha, tag, branch)
# so I leave it out for today.
#n="$(git rev-parse --abbrev-ref "$a")" && [ -n "$n" ] && n="branch $n" || n="commit $c";
#n="$(git describe --all --exact-match "$a")" && [ -n "$n" ] || n="$c";
b fake-merge <<'EOF'
declare -A HAVE;
i=0;
b=;
P=();
for a in HEAD "$@";
do
	c="$(git rev-parse --verify "$a")" || { echo "cannot interpret $a" >&2; exit 1; };
	[ -z "${HAVE["$c"]}" ] || { echo "WARN: ignore already seen commit $a" >&2; continue; };
	HAVE["$c"]=1;
	P+=(-p "$c");
	if [ -z "$b" ]; then b="Fake-Merge"; else b="$b $a,"; fi;
done;
ob="$(git write-tree)" || { echo "git-write-tree failed, aborting" >&2; exit 1; };
cc="$(git commit-tree "${P[@]}" -m "${b:0:-1} into $(git rev-parse --abbrev-ref HEAD)" "$ob")" && git ff "$cc"
EOF


# See http://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command#comment9747528_957978
a exec	'!exec '
a make	'!exec make'
# See https://gist.github.com/hilbix/7724772
b top	<<'top-EOF'
GIT_TOP="${GIT_DIR%%/.git/modules/*}";
[ ".$GIT_TOP" != ".$GIT_DIR" ] && cd "$GIT_TOP";
unset GIT_DIR;
exec "$@";
top-EOF

s tig.show-rev-graph yes
a all	!tig --all
a tig	!tig --all

a run	'!f() { cd "$GIT_PREFIX" && exec "$@"; }; f'			# Like 'git exec' but stay in current directory
a bash	'!f() { cd "$GIT_PREFIX" && exec bash -c "${*:-set}"; }; f'	# "git bash x" is short for "git run bash -c x" where x defaults to "set"
a dir	'!f() { cd "$GIT_DIR" && exec "${@:-"$SHELL"}"; }; f'		# enter/run in associated GIT_DIR

# Switch to another branch, just moving head and NOT affecting workdir
# See https://stackoverflow.com/a/45060070
a switch '!f() { git contained && git rev-parse --verify "$*" && git checkout "HEAD^{}" && git reset --soft "$*" && git checkout "$*"; }; f'

# See https://gist.github.com/hilbix/7703225
# Basic idea from https://gist.github.com/jehiah/1288596
# f() trick from http://stackoverflow.com/questions/7005513/pass-an-argument-to-a-git-alias-command
a relate '!f(){ x="$1"; case "$#" in 0|1) git for-each-ref --format="%(refname:short) %(upstream:short)" refs;; *) shift; for a in "$@"; do echo "$a"; done;; esac | while read -r l r; do printf "%24s %s\\n" "$(git rev-list --cherry-mark --dense --left-right --boundary --oneline "${x:-${r:-HEAD}}...$l" -- | sed "s/^\\(.\\).*/\\1/" | sort | uniq -c | tr -d " " | tr "\\n" " ")" "${x:-${r:-HEAD}}...$l"; done; }; f'
a dograph '!graph(){ case "$#:$3" in 2:) r="HEAD...HEAD@{u}";; 3:*...*) r="$3";; 3:*) r="HEAD...$3";; *) r="$3...$4";; esac; r1="$(git rev-parse "${r%%...*}")"; r2="$(git rev-parse "${r##*...}")"; echo "$r - $r1 - $r2"; r1s=" $(git rev-parse --short "$r1") "; eval "v=\"\$$1\""; if [ ".$r1" = ".$r2" ]; then git pageat "${v# }" log --color=always $2 -1 "$r1"; else git pageat "$v" rev-list --color=always --cherry-mark --dense --left-right --boundary $2 --graph "$r1...$r2" --; fi; }; graph'
a graph '!git dograph r1 --pretty'
a graph1 '!git dograph r1s --oneline'

# This is "git cherry" with something like an UI
a carry	!git-carry.sh

# Upcoming: Formerly gitstart-add.sh and gitstart-ls.sh, in future git-ssh.sh
a ssh !git-ssh.sh

