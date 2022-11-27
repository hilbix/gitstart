#!/bin/bash
#
# This tries to detect and avoid known git problems
# with typical shell based setups.
#
# If you know more, please open Issue at https://github.com/hilbix/gitstart/issues
#
# Run this script with "setsid" (like: "setsid make") to prevent /dev/tty interaction.

dash()
{
  printf -- '------------------------------------------------------------------------\n'
  [ -z "$*" ] || { printf '%s\n' "$1" && dash "${@:2}"; }
}

halt()
{
  dash "Press RETURN to continue." >/dev/tty && read </dev/tty || :
}

check-bare-git()
{
  code="$(cd "$(dirname -- "$0")/security-test" && HOME="$1" script -c 'git log' -q /dev/null)"
  [ 'all your base are belong to us' != "${code%$'\r'}" ]
}

check-bare()
{
  git config --global safe.bareRepository explicit || return
  git config --local --unset safe.bareRepository || :

  check-bare-git / && return

  dash '!! EXTREME SECURITY RISK ALERT !!'
  cat <<EOF

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

EOF
  dash '!! EXTREME SECURITY RISK ALERT !!'

  if	check-bare-git "$HOME"
  then
        cat <<EOF
safe.bareRepository was set in your --global .gitconfig which hopefully
is able to protect you.  However this setting can be overridden by local
git configurations, hence you are not entirely safe until this issue has
been dealt with in git itself.  Thanks for your understanding.
EOF
        dash
  else
        cat <<EOF
Either your git is too old to be able to protect you against this,
or the workaround setting safe.bareRepository to explicit failed.

PLEASE CHECK OR CONSIDER UPGRADING TO GIT 2.38 OR ABOVE!
EOF
        HALT=:
  fi
}

run()
{
  HALT=false

  check-bare ||
  # add more checks here

  return
  $HALT || return 0
  halt
}

run && exit

dash 'WARNING!  CHECK FAILED.  Sorry!  Please press RETURN to continue' >&2
read </dev/tty
exit 1

