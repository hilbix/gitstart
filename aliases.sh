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

