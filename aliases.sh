#!/bin/bash

export LC_ALL=C

s()
{
git config --global --replace-all "$1" "${*:2}"
}

a()
{
s "alias.$@"
}

a alias	!git-alias.sh
a amend	commit --amend
a amit	commit --amend -C HEAD
a bvv	branch -avv
a bv	"!git branch -avv | sed 's/^/x/' | awk '\$2==\"(detached\" && \$3==\"from\" && \$4==\$5\")\" { \$2=\"HEAD\"; \$3=\$5; } \$3!=\"->\" { m[\$3]=m[\$3] substr(\$1,2); sub(/^remotes\\//,\"/\",\$2); if (!f[\$3]) { f[\$3]=\$2; if (length(\$2)>mx) mx=length(\$2); } else { l=length(\$2)-length(f[\$3]); if (substr(\$2,l)==\"/\"f[\$3]) \$2=substr(\$2,1,l); k[\$3]=k[\$3] \" \" \$2; } } END { for (a in f) printf(\"x%-1s %s %-*s %s\\n\", m[a], a, mx, f[a], k[a]); }' | sort -bk2 | sed 's/^x//'"
# Same for tags
a tv	"!{ git tag --format='%(objectname)	%(refname:strip=2)'; git remote | while read -r n; do echo -n \" \$n\" >&2; git ls-remote --tags \"\$n\" | awk -F'\\t' -vN=\"\$n\" '{ sub(/^[^/]*\/[^/]*/,\"\",\$2); print \$1 \"\\t/\" N \$2 }'; done; echo >&2; } | sort -r | awk '{ if (!f[\$1]) { f[\$1]=\$2; if (mx<length(\$2)) mx=length(\$2); } else { l=length(\$2)-length(f[\$1]); if (\"/\"f[\$1]!=substr(\$2,l)) l=length(\$2); m[\$1]=m[\$1] \" \" substr(\$2,0,l); } } END { for (a in f) printf(\"%s %-*s %s\\n\", a, mx, f[a], m[a]); }' | sort"
a check	diff --check
a co	checkout
a pager	'!pager() { cd "$GIT_PREFIX" && git -c color.status=always -c color.ui=always "$@" 2>&1 | less -XFR; }; pager'
a pageat '!pager() { at="$1" && shift && cd "$GIT_PREFIX" && git -c color.status=always -c color.ui=always "$@"  2>&1 | less -XFRp "$at"; }; pager'
a tree	'!cd "$GIT_PREFIX" && git pager log --color=always --graph --oneline --decorate --all'
a ls	'!cd "$GIT_PREFIX" && git pager log --color=always --graph --oneline --decorate'
a ll	'!cd "$GIT_PREFIX" && git pager log --color=always --graph --oneline --decorate --numstat'
a la	'!cd "$GIT_PREFIX" && git pager log --color=always --graph -u --decorate'
a st	'!cd "$GIT_PREFIX" && git pager status'
a up	status
a squash rebase --interactive
#a fastforward # git fetch; git fastforward -> ff all branches which can do so, flag which cannot

# As suggested by Daniel Brockman, see http://stackoverflow.com/questions/957928/is-there-a-way-to-get-the-git-root-directory-in-one-command#comment9747528_957978
a exec	'!exec '
a make	'!exec make'
# See https://gist.github.com/hilbix/7724772
a top '!f() { GIT_TOP="${GIT_DIR%%/.git/modules/*}"; [ ".$GIT_TOP" != ".$GIT_DIR" ] && cd "$GIT_TOP"; unset GIT_DIR; exec "$@"; }; f'

s tig.show-rev-graph yes
a all	!tig --all
a tig	!tig --all

# Switch to another branch, just moving head and NOT affecting workdir
a switch '!f() { git show-ref --heads --verify "refs/heads/$1" && git symbolic-ref -m "switch to branch $1 not touching workdir" HEAD refs/heads/"$1"; }; f'

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

