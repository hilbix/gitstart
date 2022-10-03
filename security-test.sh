#!/bin/bash
#
# If this outputs
#	all your base are belong to us
# then you are vulnerable to malicious git code execution!

check()
{
# https://unix.stackexchange.com/a/249726
code="$(cd "$(dirname -- "$0")/security-test" && script -c 'git log' -q -)"
[ 'all your base are belong to us' != "${code%$'\r'}" ]
}

run()
{
git config --global safe.bareRepository explicit || return
git config --local safe.bareRepository all || return

check && return

cat <<EOF
------------------------------------------------------------------------

!! EXTREME SECURITY RISK ALERT !!

Your git is vulnerable to the
	Unexpected Arbitrary Code Execution Attack
for Bare Repositories included in some repository.

URL: https://github.com/justinsteven/advisories/blob/main/2022_git_buried_bare_repos_and_fsmonitor_various_abuses.md

After cloning any, I repeat, ANY git repository out there,
your system may be taken over by some attacker.
Only using your own repositories which are signed and verified
from and by you can protect you.  Everything else is unsafe.

All repositories out there which contain subdirectories impose
this danger to you.  Already looking into the directory may
trigger the attack if you work with the recommended environment.

Entering an infected subdirectory and running a simple commands like
	git log
from terminal can execute any code which was defined by the attacker.

When you have installed the usual recommended git shell helpers,
then even listing or entering the directory alone might trigger the
malicious code (so you do not need to enter a git command yourself,
as the shell does this for you).

!THE GIT MAINTAINERS NEGLECT THAT THIS IS A SECURITY BUG OF git!
Please write a letter to them, explaining your opinion on this.
(Sorry, no pointers here whome to write.  Please find out yourself.)

Thank you very much.

------------------------------------------------------------------------
EOF

git config --local --unset safe.bareRepository || return

if	check
then
	cat <<EOF
safe.bareRepository was set in your global .gitconfig which hopefully
is able to protect you.  However this setting can be overridden by local
git configurations, hence you are not entirely safe until this issue has
been dealt with in git itself.  Thanks for your understanding.
------------------------------------------------------------------------
EOF
else
	cat <<EOF
Apparently your git is too old to be able to protect you against this.

PLEASE CONSIDER UPGRADING TO GIT 2.38 OR ABOVE!

Please press RETURN to continue.
------------------------------------------------------------------------
EOF
	read </dev/tty
fi
}

run && exit

echo -n "WARNING!  CHECK FAILED.  Please press RETURN to continue: "
read </dev/tty
exit 1

