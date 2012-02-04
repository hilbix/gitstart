Random notes stored here

Links
=====

- http://progit.org/book/ probably the best source about how to get started with GIT


Convenience tips
================

Bash completion
---------------

On Debian there is `/etc/bash_completion.d/git` which is automatically sourced if `bash-completion` is installed.  To enable this you just need to alter your `~/.bashrc` to include `$(__git_ps1 "(%s)")` before the `\$` on lines matching the pattern `PS1='.*\$ '` (which do not already include __git_ps1 yet).

A script named `fix-bashrc.sh` does this for you.


Safety tips
===========

Single source
-------------

If you have a single source which pushes to a remote server, then you should remove the `+` from `.git/config`'s `[remote "origin"]` line `fetch =`.  This way if you do `git pull` or `git fetch` this will fail if it is not `fast forward`.

What does this mean?

* Suppose you have only have a single source which always pushes to the remote.
* Suppose that somebody else tamperes with your remote GIT repository by introducing some new head.
* Suppose you pull from your repository to other machines.

Now with the `+` in place you will not notice anything on `git fetch`.  But without this `+` the `git fetch` will fail in such a case.

For example:

* You clone a remote repository.
* You remove the `+` from the `.git/config`'s `[remote "origin"]` section.
* Somebody compromizes the remote repository
* You `fetch` the compromized version.
* The breach in is recognized and the remote repository is cleaned up.  However you are not aware.
* You `fetch` again and get an ugly error.  This is due to the `+` is missing and there is no `fast forward` from the compromized version to your version.
* The `fetch` will not automatically attempt to do a 3-way-merge as the `+` is missing.  So you will be informed that something is wrong.
* Now that you are aware, you look at the remote and can read up about the compromized version and can take action.
* Without this fix, you probably overlook that it was a merge and continue to use the compromized version until you some time later - perhaps - notice that your local version and the remote one diverged at some point.

