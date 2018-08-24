**This already is useful to others!**


Helpers for Git and GitHub
==========================

Some tools to quickly access and process GitHub repositories and similar.

It needs BASH and probably only run on Linux.


Setup:
------

On each machine:

```bash
git clone https://github.com/hilbix/gitstart
make install
```

This installs everything:

- runs `aliases.sh`
- runs `fix-bashrc.sh`
- installs `gitstart-add.sh` as `~/.ssh/.add` (a location which can be easily found)
- installs `git-carry.sh` in `~/bin/`


Usage:
------

After install:

* `~/.ssh/.add [REPO [ACCOUNT]]` add a repository deployment key and tells you what to do.  `REPO` is taken from the current path.  `ACCOUNT` needs to be given on the first invocation only.  Try `~/.ssh/.add '' YOURGITHUBACCOUNT`.  It is idempotent, so you can run it multiple times and it always does the same.

Aliases:
--------

This adds some GIT aliases.  Short documentation here:

* `git st`: `git status | less`
* `git bv`: summary for `git branch -av` with branches combined
* `git bv.ign tag..`: ignore some branches in `git bv` output.  Opposite (enable again) is `git bv tag..`
* `git bvv`: shortcut to `git branch -avv` (completes `git bv`)

* `git amend`: `git commit --amend`.  BUG: Does not check for the replaced commit beeing pushed already, which will break origin.
* `git amit`: `git commit --amend -C HEAD`: Just edit the last commit message again ignoring the index.  BUG: The command does not check yet if the current commit already was pushed (in which case you probably never want to use `--amend`).
* `git check`: `git diff --check`
* `git co`: `git checkout`
* `git ls`: `git log --graph --oneline`
* `git tree`: is `git ls --all`

* `git exec`: Runs a command at top level of the Worktree where the `.git` directory or `.git` file of the current Repo lives.  Try `git exec pwd`.  Note that this works for bare Repos, too.
* `git run`: Like `git exec`, but in current directory
* `git make`: Shorthand for `git exec make`
* `git top`: Runs a command at the topmost level of Worktrees where the `.git` directory lives.  If you do not use `git submodule`s or your submodules do not use `.git` files, then it is similar to `git exec`.  Try `git top git submodule status --recursive`.  Note that this does not work for bare repos.
* `git dir`: Runs a command in the `GIT_DIR`.  If command is missing, it enters a subshell in this directory.
* `git bash x`: Alias for `git run bash -c x` where `x` defaults to `set`

* `git tig` or `git all`: `tig --all`
* `git relate [commit]`:  Show how the other branches relate to the given one, `HEAD` by default.
* `git graph [commit[...]commit]`:  Shows a track chart of the given commits.  By default the current HEAD to it's upstream.  You can give `commit` which is `HEAD...commit` or `commit1...commit2` which is similar to `commit1 commit2`
* `git graph1 [commit[...]commit]`:  As `git graph` but uses a single line for each commit.

Things which are very special to me:

* `git carry [commit[...]commit]`: Interactively cherry-pick (cherry .. carry .. you get it) commits found in the given repository and missing locally.  This needs to find `git-carry.sh` in the current path.  By default it tries the current `BRANCH` to `upstream/BRANCH` (not: `origin`!).  Example: `git carry upstream/master` which is equivalent to `git carry` if you are on `master`.

* `git up`: `git status`  (this is because I always abused `cvs up` for what `git status` does today)


Rationale:
----------

I work on many machines and I love to edit things anywhere.  For security reasons all repository access is done via individual Deploy Keys on GitHub, so I can revoke one quickly.  L accounts on M machines with N repositories needs LxMxN SSH keys.  Go figure.

This here bundles all the everywhere needed shell helpers, allowing me to do what I want quickly everywhere.

See also http://permalink.de/tino/github


Contact:
--------

If something does not work as expected, please try to fix it yourself.  If you think your changes are interesting, please send me a pull request on GitHub.

Please note that I cannot read my mail due to SPAM.  So better use my pager (URL see GitHub) wisely, as I will ignore messages which are errornously marked important.  Thank you for your understanding.
 

License:
--------

This Works is placed under the terms of the Copyright Less License,
see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

