#!/bin/bash

export LC_ALL=C.UTF-8 || export LC_ALL=C

q() { sed "s/'/'\\\\''/g"; }
s() { git config --global --replace-all "$1" "${*:2}"; }
a() { s "alias.$@"; }
# bash wrapper
b() { a "$1" "!LC_ALL=$LC_ALL bash -c  '$(q)' --"; }
x() { a "$1" "!LC_ALL=$LC_ALL bash -xc '$(q)' --"; }

# Ask the user a Y/N question, where the default is N
# $1 is meant to be the storage key for .git/config in format name.$KEY.tag
# $1==false is an alias for /bin/false
# Improvements for future:
# - L remember local
# - G remember global
# - `git confim` lists known choices
b confirm <<'EOF-confirm'
{
[ false != "$1" ] || exit;
printf '%q:' "${1%%.*}" && printf ' %q' "${@:2}" && printf ' [y/n]? ' &&
read -sn1 ans &&
case "$ans" in ([yY]) printf 'Yes\n'; exit 0;; esac;
printf 'No\n';
} >&2;
exit 1;
EOF-confirm

# Mirror your dev-tree to the given directory
b mirror <<'EOF-mirror'
DIR="$(git config --local --get mirror.dir 2>/dev/null)" ||
DIR="$(git top git config --get mirror.dir 2>/dev/null)"
ASK="git confirm";
while	case "$1" in
	(-y)	ASK=:;;
	(*)	false;;
	esac;
do shift; done;
case "$#:$1" in (1:.) set -- "${DIR:-"$(readlink -m "$HOME/gitmirror")"}" || exit;; esac;
case "$#" in
(0)	[ -z "$DIR" ] || { set -- "$DIR" && $ASK mirror."$DIR".default use "$DIR" || exit; }; false;;
(1)	NEW="$(readlink -m -- "$1")" && [ ! -e "$NEW" -o -d "$NEW" ] || { printf 'not usable: %q\n' "$1" >&2; exit 1; };
	TOP="$(git top)" || exit;
	case "$NEW" in ("$TOP"|"$TOP/"*) printf 'target must be outside of git tree: %q\n' "$TOP" >&2; exit 1;; esac;
	set -- "$NEW";
	if [ -z "$DIR" ];
	then
		$ASK mirror."$NEW".default set "$NEW" as default;
	elif	[ ".$NEW" = ".$DIR" ];
	then
		false;
	else
		$ASK mirror."$NEW".default replace default "$DIR" with "$NEW";
	fi;;
(*)	false;;
esac &&
{
set -- "$NEW";  # NOT redundant
[ ! -e "$NEW" -o -d "$NEW" ] || { printf 'not usable: %q\n' "$1" >&2; exit 1; };
git config --local mirror.dir "$NEW";
}
[ 1 = $# ] || { printf 'Usage: git mirror [-y] [DIR|.] -- recursively mirror submodule devtree into dir\n' >&2; exit 42; };

# see https://github.com/hilbix/tino/blob/46c7cf43d04ffd9bb9f647102408b0c5c9c1bcbf/datenschutz/security.md#verified

MIRROR="$1";
if [ ! -d "$MIRROR" ]; then $ASK mirror."$MIRROR".create create "$MIRROR/" && mkdir -p "$MIRROR" || exit; fi;

git-do() { HOME="$MIRROR" GIT_CONFIG_NOSYSTEM=1 git "$@"; }

git-all()
{
git-do "$@";
git-do submodule -q foreach --recursive "git $(printf ' %q ' "$@")";
}

OOPS()
{
{
printf '\nOOPS:'
printf ' %q' "$@";
printf '\n\n'
} >&2;
exit 23;
}

o-git-all()
{
git-all "$@" || OOPS failed: "$@"
}

cleanup()
{
{
"$@";
echo "#END#"$'\t'"$?";
} 2>&1 |
{
ret=;
while IFS=$'\t' read -r a b c;
do
	ret=;
	if [ -z "$b$c" ]
	then
		b="${a%% *}";
		c="${a#"$b"}";
		case "$b $c" in
		('To '*)	printf o; targ="${c#"$MIRROR/git/"}"; continue;;
		('Done ')	continue;;
		esac;
	else
		case "$a" in
		('#END#')	ret="$b"; continue;;
		('=')		printf _; continue;;
		('*')		printf +; continue;;
		(' ')		printf u; continue;;
		('+')		printf F; continue;;
		esac;
	fi
	printf '\n';
	OOPS unexpected output: "$a" -- "$b" -- "$c";
done;
printf '\n';
case "$ret" in
('')	OOPS "missing end marker";;
(0)	return 0;;
(*)	return 1;;
esac;
}
}

# 1st: Create the ".insteadOf" entries, using the mirror directory
MIRROR="$MIRROR/nope" git-all remote get-url --push origin |
sed -n -e 's/:[^/].*$/:/p' -e 's!\([^/]\)/[^/].*$!\1/!p' |
sort -u |
while read -r a; do
  b="${a/:/}"; b="${b/\/\//_}"; b="${b//:/_}";
  HOME="$MIRROR" git config --global "url.$MIRROR/git/${b%/}/.insteadOf" "$a";
done;

# 2nd: Create the bare repositories for storage in it
MIRROR="$MIRROR/nope" git-all remote get-url --push origin |
while read -r a; do
  b="${a/:/}"; b="${b/\/\//_}"; b="${b//:/_}";
  [ -d "$MIRROR/git/$b" ] || git-do init --bare "$MIRROR/git/$b";
done;

#git-do config --global push.default current;
git-do config --global push.default nothing;

# forces an update the mirror to act as "origin"
printf 'P';
cleanup o-git-all push --force --porcelain origin 'refs/remotes/origin/*:refs/heads/*' 'refs/tags/*:refs/tags/*'

# Also "backup" current local branches
# XXX TODO XXX T.B.D.
# To safe:  refs/*:refs/host/$(hostname -f)/$LOCATION/*
#git-all push --force --porcelain origin "refs/stash/*:refs/stash/*";
#git-all push --quiet --porcelain origin 'refs/remotes/*:refs/mirror/remotes/*';
#git-all push --quiet --porcelain origin "refs/heads/*:refs/host/$(hostname -f)/*";

# Now check for inconsistencies
# This should not output anything!

printf 'B';
cleanup git-all push --porcelain origin 'refs/remotes/origin/*:refs/heads/*' ||
OOPS try: 'git remote update -p && git submodule --recursive foreach git remote update -p';

printf 'T';
cleanup git-all push  --porcelain origin "refs/tags/*:refs/tags/*" ||
OOPS tags are inconsistent.  You must manually repair this.;

echo "WARNING: Mirroring is preliminary (and terribly incomplete)"
EOF-mirror

a amend	commit --amend
a amit	commit --amend -C HEAD
a bvv	branch -avv
b bv.ign <<<'for a; do git config --local --get-all ignore.bv | fgrep -qx "$a" || git config --local --add ignore.bv "$a"; done'
b bv	<<'EOF-bv'
for a; do git config --local --unset ignore.bv "$a"; done;
{
git config --get-all ignore.bv | sed 's/^/d/';
git branch -avv | sed 's/^/x/';
} |
gawk '
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
EOF-bv
# Same for tags
b tv.ign <<<'for a; do git config --local --get-all ignore.tv | fgrep -qx "$a" || git config --local --add ignore.tv "$a"; done'
b tv <<'EOF-tv'
for a; do git config --local --unset ignore.tv "$a"; done;
{
while read -ru6 tag; do printf '%s\t%s\n' "$(git rev-parse "refs/tags/$tag" || echo .)" "$tag"; done 6< <(git tag --no-column);
while read -ru6 n;
do
	printf '/%q/' "$n" >&2;
	git config --get-all ignore.tv | fgrep -qx "/$n/" && { printf ':ign ' >&2; continue; }
	{
	trap 'printf "try: git tv.ign /%q/\n" "$n" >&2; exit 1' SIGINT;
	if	git ls-remote --tags "$n" 2>/dev/null;
	then
		printf ':ok ' >&2;
	else
		printf '=%s ' $? >&2
	fi;
	} |
	grep -vG '\^{}$' |
	gawk -F'\t' -vN="$n" '{ sub(/^[^/]*\/[^/]*/,"",$2); print $1 "\t/" N $2 }';
done 6< <(git remote);
echo >&2;
} |
sort -r |
gawk '
	{
	if (!f[$1])	{ f[$1]=$2; if (mx<length($2)) mx=length($2); }
	else		{ l=length($2)-length(f[$1]);
			  if ("/"f[$1] != substr($2,l)) l=length($2);
			  m[$1]=m[$1] " " substr($2,0,l);
			}
	}
END	{ for (a in f) printf("%s %-*s %s\n", a, mx, f[a], m[a]); }
' |
sort
EOF-tv
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
b isclean <<<'ok="$(git status --porcelain)" && [ -z "$ok" ] && exit; printf "${@:-$'\''not clean\n'\''}"; exit 1'
a ss	'!cd "$GIT_PREFIX" && git pager submodule summary'
# not easy to pass additional parameters to subnodule foreach, when you need '$toplevel' etc.
# git su: update all
# git su path: update only this path
# git su path/: update all in this path, not this path
# git su -r: update all recursively
# git su -r path: update only path
# git su -i: ignore errors
# git su -q: quiet
b su <<'su-EOF'
cd "$GIT_PREFIX" || exit;
args='';
[ 0 = $# ] || printf -vargs " %q" "$@";
git pager submodule -q foreach 'git sane-submodule-update-from-submodule-foreach "$toplevel" "$path" "$name" "$sha1"'"$args"
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
ignore=false;
quiet=false;
dirt='\n';
while	case "$1" in	# I am lazy
	-r*|--r*)	args+=(--recursive); recurse=:; true;;
	-i*|--i*)	args+=(--ignore); ignore=true; true;;
	-q*|--q*)	args+=(--quiet); quiet=true; dirt=; true;;
	-*)		echo "Usage: git su [-recursive|-ignore|-quiet] [--] [path..]" >&2; exit 42;;
	*)		false;;
	esac;
do
	shift;
done;
case "$1" in
--)		shift;;			# Do not harm others with my laziness.
esac;
[ 0 = $# ] && set -- '';
$quiet || printf "Entering '%q'\\n" "$pat";

# Move this here to given $sha
update()
{
# check if it is dirty, if so, do not change (as we are editing)
git isclean "$dirt"'# MODULE not clean: %q/%q\n'"$dirt" "$top" "$pat" >&2 || { $ignore || exit; return 1; }
# first try some ff to the given SHA
was="$(git rev-parse HEAD)";
[ ".$was" = ".$sha" ] && { $quiet || printf 'ok %q\n' "$sha"; };
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
b wipe	<<'wipe-EOF'
hi() { printf "$@" >&2; };
nope() { e=$?; hi '\nnot wiped:'; hi ' %q' "$@"; hi '\n'; exit $e; };
[ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ] || nope missing "$GIT_DIR";
git fsck || nope damaged repo;
hi 'This prunes refs/reflog/orphan NOW.  Type WIPE and Return: ';
for a in W I P E '';
do
	w=x;
	read -rn1 w && [ ".$a" = ".$w" ] || nope key "$w";
done;
rm -rf "$GIT_DIR/refs/original/" "$GIT_DIR/"*_HEAD;
git reflog expire --expire-unreachable=now --all;
git fsck || nope damaged repo;
git gc --prune=now --aggressive;
wipe-EOF

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
gawk -vP="(${ARGS:3})" '
/^[\t]/	{ sha=$1; next }
$0 ~ P	{ print sha "\t" $0; ret=1 }
END	{ exit 1-ret }'
find-EOF
b qf <<'qf-EOF'
cd "$(git dir /bin/pwd)";
x="$(find objects -type f | sort | md5sum)";
cmp -s quickfind.status.tmp <<<"$x" ||
{
echo -n "indexing .." >&2;
git log -C -M -B --pretty=format: --name-status --all | sort -k2 | sed '/^$/d' | uniq -c > quickfind.list.tmp && echo "$x" > quickfind.status.tmp;
echo " done" >&2;
};
egrep "${@:-.}" < quickfind.list.tmp;
qf-EOF
# find SHAs of exact commit messages:
# git exact [MESSAGE|-C COMMITISH] [HEAD|--all|RANGE]
b exact <<'exact-EOF'
HEAD=HEAD
SUFFIX=
[ -n "$1" ] || set -- -C "$HEAD" "${@:2}"
[ 2 -le $# ] &&
case "$1" in
(-c)	shift; true;;
(-C)	shift; HEAD="${1:-$HEAD}"; SUFFIX='^'; true;;
(-m)	shift; false;;
(*)	false;;
esac && set -- "$(git cat-file -p "${ARGS[0]:-$HEAD}" | sed '0,/^$/d')" "${@:2}";
[ -z "$2" ] && set -- "$1" "$(git rev-parse --verify "$HEAD@{u}" >/dev/null 2>&1 && echo "$HEAD@{u}..")$HEAD$SUFFIX" "${@:3}";

# This format hopefully never changes
git log --raw "${@:2}" |

# Converts the log into some NUL terminated lines
# Lines starting with a TAB are SHAs
# as git commit messages never start with a TAB.
gawk '
/^$/		{ printf "%c", 0; next }
/^commit /	{ printf "\t%s", $2 }
/^    /		{ sub(/^    /,""); print }' |

# Now search for the exact commit message
gawk -vA="$1"$'\n' '
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
# use -a and -c to set the commit's AUTHOR or COMMITER date from the commit which follows.
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
m=;
P=();
a=false;
c=false;
for b in HEAD "$@";
do
	[ .-a = ".$b" ] && { a=:; continue; }
	[ .-c = ".$b" ] && { c=:; continue; }
	p="$(git rev-parse --verify "$b")" || { echo "cannot interpret $b" >&2; exit 1; };
	$a &&    GIT_AUTHOR_DATE="$(git show -s --format=%ai "$p")" && export    GIT_AUTHOR_DATE && a=false;
	$c && GIT_COMMITTER_DATE="$(git show -s --format=%ci "$p")" && export GIT_COMMITTER_DATE && c=false;
	[ -z "${HAVE["$p"]}" ] || { echo "WARN: ignore already seen commit $b" >&2; continue; };
	HAVE["$p"]=1;
	P+=(-p "$p");
	if [ -z "$m" ]; then m="Fake-Merge"; else m="$m $b,"; fi;
done;
ob="$(git write-tree)" || { echo "git-write-tree failed, aborting" >&2; exit 1; };
cc="$(git commit-tree "${P[@]}" -m "${m:0:-1} into $(git rev-parse --abbrev-ref HEAD)" "$ob")" && git ff "$cc"
EOF


# See http://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command#comment9747528_957978
a exec	'!exec '
a make	'!exec make'
# See https://gist.github.com/hilbix/7724772
b top	<<'top-EOF'
GIT_DIR="$(git dir /bin/pwd)";
GIT_TOP="${GIT_DIR%%/.git/modules/*}";
[ ".$GIT_TOP" != ".$GIT_DIR" ] && cd "$GIT_TOP";
unset GIT_DIR;
exec "${@:-/bin/pwd}";
top-EOF

s tig.show-rev-graph yes
a all	!tig --all
a tig	!tig --all

a run	'!f() { cd "$GIT_PREFIX" && exec "$@"; }; f'			# Like 'git exec' but stay in current directory
a bash	'!f() { cd "$GIT_PREFIX" && exec bash -c "${*:-set}"; }; f'	# "git bash x" is short for "git run bash -c x" where x defaults to "set"
b dir	<<<'cd "${GIT_DIR:-"$(git rev-parse --git-dir)"}" && exec "${@:-"$SHELL"}"'	# enter/run in associated GIT_DIR

# Hop onto another branch, just moving head and NOT affecting workdir
# See https://stackoverflow.com/a/45060070
a hop '!f() { git contained && git rev-parse --verify "$*^{commit}" && git checkout "HEAD^{}" && git reset --soft "$*" && git checkout "$*"; }; f'

# See https://gist.github.com/hilbix/7703225
# Basic idea from https://gist.github.com/jehiah/1288596
# f() trick from http://stackoverflow.com/questions/7005513/pass-an-argument-to-a-git-alias-command
b relate <<'EOF-relate'
x="$1";
case "$#" in
0|1)	git for-each-ref --format="%(refname:short) %(upstream:short)" refs;;
*)	shift; for a in "$@"; do echo "$a"; done;;
esac |
while read -r l r;
do
	printf "%24s %s\\n" "$(git rev-list --cherry-mark --dense --left-right --boundary --oneline "${x:-${r:-HEAD}}...$l" -- | sed "s/^\\(.\\).*/\\1/" | sort | uniq -c | tr -d " " | tr "\\n" " ")" "${x:-${r:-HEAD}}...$l";
done;
EOF-relate
a dograph '!graph(){ case "$#:$3" in 2:) r="HEAD...HEAD@{u}";; 3:*...*) r="$3";; 3:*) r="HEAD...$3";; *) r="$3...$4";; esac; r1="$(git rev-parse "${r%%...*}")"; r2="$(git rev-parse "${r##*...}")"; echo "$r - $r1 - $r2"; r1s=" $(git rev-parse --short "$r1") "; eval "v=\"\$$1\""; if [ ".$r1" = ".$r2" ]; then git pageat "${v# }" log --color=always $2 -1 "$r1"; else git pageat "$v" rev-list --color=always --cherry-mark --dense --left-right --boundary $2 --graph "$r1...$r2" --; fi; }; graph'
a graph '!git dograph r1 --pretty'
a graph1 '!git dograph r1s --oneline'

# "git bring file" is the opposite of "git fetch file". Defaults to commits not on upstream
# "git pull file" does "git fetch file && git ff FETCH_HEAD".
# "git bundle unbundle file" reads it and prints the commits you can give a name
b bring <<'EOF-bring'
[ -n "$1" ] || set -- "$(mktemp --suffix=.bundle)" "${@:2}";
[ -n "$2" ] || set -- "$1" "@{u}..." "${@:3}";
git bundle create "$@" &&
ls -al "$1";
EOF-bring

##
## Not ready below
##

# Safely jump from some detached head state to some other branch possibly doing an ff of this branch.
# In other words: It is like a "git co && git ff $CURRENTHEAD" without touching the worktree.
# If no branch is given the nearest branch which does not jump beyond it's tracking branch is used.
# This is meant to be used with `git su` in case you are get into detached head state.
# "git coff [branch [commit]]"
b coff	<<'EOF-coff'
explicite=false;
LIST=("$@")
if [ 0 = $# ];
then
	explicite=:
fi
# explicicte
# pick our location
# find next nearest branch (or take the given ones)
# take the nearest one
# check the tracking location of this branch
EOF-coff

# Branch fast-forward
# This fast-forwards a branch we are not on.
# Format is branch (tracking) or branch=commit (to the given commit)
# By default it automatically fast-forwards all other tracking branches
# "git bff [branch=commit].."
b bff	<<'EOF-bff'

EOF-bff

