#!/bin/bash

s()
{
git config --global --replace-all "$1" "${*:2}"
}

a()
{
s "alias.$@"
}

a amend	commit --amend
a amit	commit --amend -C HEAD
a check	diff --check
a co	checkout
a ls	log --graph --oneline
a st	status
a up	status

s tig.show-rev-graph yes
a all	!tig --all

