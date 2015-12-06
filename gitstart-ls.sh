#!/bin/bash

export LC_ALL=C

list()
{
for a in "$HOME/.ssh"/*.pub
do
	ssh-keygen -l -f "${a%.pub}"
done
}

if [ 0 = "$#" ]
then
	list
else
	for a
	do
		list | fgrep -- "$a"
	done
fi
