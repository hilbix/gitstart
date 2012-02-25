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

a lost-branches '!cd .git && { cd ..; git fsck --lost-found; for a in .git/lost-found/commit/*; do b="`basename "$a"`"; git checkout "$b"; git branch "lost-$b"; done; }; git branch -v'
