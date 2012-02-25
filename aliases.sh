#!/bin/bash

a()
{
a="$1"
shift
git config --global --replace-all alias."$a" "$*"
}

a amend	commit --amend
a amit	commit --amend -C HEAD
a check	diff --check
a co	checkout
a ls	log --graph --oneline
a st	status
a up	status

# Ich kriege das einfach nicht hin.
# Wie raeumt man das aktuelle Verzeichnis so beiseite,
# dass es keinerlei Probleme mehr erhaelt,
# und danach holt man es wieder exakt so zurueck wie es vorher war?
a lost-branches '!cd .git && { cd ..; TMP=`tempfile -d.`; date > TMP; git stash; o="`cat .git/HEAD`"; git fsck --lost-found; for a in .git/lost-found/commit/*; do b="`basename "$a"`"; git checkout "$b"; git branch "lost-$b"; done; git co "${o#}"; git stash pop; git branch -v'
