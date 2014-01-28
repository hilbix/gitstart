Random additional information stored here

Links
=====

- http://progit.org/book/ probably the best source about how to get started with GIT


Convenience tips
================

Bash completion
---------------

On Debian there is `/etc/bash_completion.d/git` which is automatically sourced if `bash-completion` is installed.  To enable this you just need to alter your `~/.bashrc` to include `$(__git_ps1 "(%s)")` before the `\$` on lines matching the pattern `PS1='.*\$ '` (which do not already include __git_ps1 yet).

A script named `fix-bashrc.sh` does this for you.

If your shell prompt suddenly takes ages, this might be because bash is evaluating the `git status` to prompt `PS1`.  In that case you can addjust `~/.bashrc` to your needs, just change the `git` environment variables (change the `yes` to `no`):
```bash
export GIT_PS1_SHOWDIRTYSTATE=yes
export GIT_PS1_SHOWUNTRACKEDFILES=yes
export GIT_PS1_SHOWUPSTREAM=verbose
```



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
* You `pull` the compromized version as this is `fast-forward`.  So you now are on the compromized `master` branch.  You cannot detect this, as you do not know that there is a problem with the remote repository.
* The remote detects the problem and cleans up.  However you are not aware that this happened.
* You `pull` again from the remote and now get an ugly error.  This is due to the `+` is missing and there is no `fast forward` from the compromized version to your version.
* The `pull` will not automatically attempt to do a 3-way-merge as the `+` is missing.  So you will be informed that something is wrong!
* Now that you are aware, you look at the remote and become aware, that something awful happened to it.  You can take appropriate action.
* Without removing the `+`, you probably do not notice, that the last `pull` in fact has become a `merge`, and continue to use the compromized version until you some time later - perhaps - notice that your local version and the remote one diverged at some point and the compromized code still is in place at your side.

