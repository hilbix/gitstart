#!/bin/bash

for a in "$HOME/.ssh"/*.pub
do
	ssh-keygen -l -f "${a%.pub}"
done
