**This already is useful to others!**

> **!!EXTREME!SECURITY!ALERT!!** This here sets `safe.bareRepository=explicit` as a **CRITICAL SECURITY FIX TO GIT**.
> [ALL VERSIONS OF GIT BEFORE 2.38 ARE UNSAFE TO USE](https://github.com/justinsteven/advisories/blob/main/2022_git_buried_bare_repos_and_fsmonitor_various_abuses.md),
> AND [2.38 AND ABOVE ARE ONLY SAFE TO USE IF ABOVE FIX IS APPLIED](https://github.blog/2022-10-03-highlights-from-git-2-38/)!
> (To be exact: Without this fix `git` is dangerous to use.  With this fix it is believed to be not as dangerous, but there are still ways by third party to circumvent this.)
>
> Apparently nobody accepted the horrible impact of this option yet.
> But if anybody gets into control of some repository, tricking others to execute arbitrary code [is more than trivial](security-test/config).
>
> - DO NOT USE GIT BEFORE 2.38 WITH 3RD PARTY REPOSITORIES!  **You have been warned.**
> - DO NOT USE GIT FROM 2.38 AND ABOVE WITHOUT `safe.bareRepository=explicit`!  **You have been warned!**
>
> Note that his security flaw is not in my repo here, but it did not mitigate this risk before.  Sorry, as I was not aware!


Helpers for Git and GitHub
==========================

Some tools to quickly access and process GitHub repositories and similar.

It needs BASH and probably only run on Linux.


Setup:
------

On each machine:

```bash
git clone https://github.com/hilbix/gitstart
cd gitstart
make install
```

This installs everything:

- runs `aliases.sh`
- runs `fix-bashrc.sh`
- installs `gitstart-add.sh` as `~/.ssh/.add` (a location which can be easily found)
- installs `gitstart-ls.sh` as `~/.ssh/.list` (a location which can be easily found)
- installs `git-carry.sh` and `git-alias.sh` in `~/bin/`


Usage:
------

After install:

* `~/.ssh/.add [REPO [ACCOUNT]]` add a repository deployment key and tells you what to do.  `REPO` is taken from the current path.  `ACCOUNT` needs to be given on the first invocation only.  Try `~/.ssh/.add '' YOURGITHUBACCOUNT`.  It is idempotent, so you can run it multiple times and it always does the same.


Commands:
---------

* `git alias`: show all git aliases, indented

* `git hdiff BRANCH`: finds a diff to the branch and branch's history.  `branch` defaults to `master`
  - If you have a working branch which is partially merged to `master`, then `git diff` does not work very well.
  - This here ignores all things which are already in master somewhere, even if heavily modified later.
  - It also detects the minimum diff to the history, such that you hopefully can quickly see what has really changed

Things which are very special to me:

* `git carry [commit[...]commit]`: Interactively cherry-pick (cherry .. carry .. you get it) commits found in the given repository and missing locally.  This needs to find `git-carry.sh` in the current path.  By default it tries the current `BRANCH` to `upstream/BRANCH` (not: `origin`!).  Example: `git carry upstream/master` which is equivalent to `git carry` if you are on `master`.
  - TODO: Use `git notes` instead of directory `.gitcarry`, as the latter is plain stupid


Aliases:
--------

This adds some GIT aliases.  Short documentation here:

* `git st`: `git status | less`
* `git bv`: summary for `git branch -av` with branches combined
* `git bv.ign tag..`: ignore some branches in `git bv` output.  Opposite (enable again) is `git bv tag..`
* `git bvv`: shortcut to `git branch -avv` (completes `git bv`)
* `git tv.ign /remote/`: `git tv` needs to connect to the remote, so you can ignore those which are done.  
  Uses `/remote/` for remotes to allow future extension to ignore tags.  Opposite (enable again) is `git tv /remote/`
* `git tv`: similar to `git bv`, but for tags
* `git ls`: `git log --graph --oneline`
* `git tree`: is `git ls --all`
* `git check`: `git diff --check`
* `git switch BRANCH`: switch to another branch leaving worktree and index untouched.

* `git co`: `git checkout`
* `git amend`: `git commit --amend`.  BUG: Does not check for the replaced commit beeing pushed already, which will break origin.
* `git amit`: `git commit --amend -C HEAD`: Just edit the last commit message again ignoring the index.  
   BUG: The command does not check yet if the current commit already was pushed (in which case you probably never want to use `--amend`).
* `git squash`: `git rebase --interactive`
* `git fixup`: `git rebase --interactive --autosquash`

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

* `git find PATTERN`: search for `egrep`-`PATTERN` in the whole repository.  If `PATTERN` is missing, it just outputs all files (unsorted: what file)
* `git qf PATTERN`: like `find` but re-uses an index for faster multiple searches of bigger repos (sorted: count what file)
* `git exact [''|[-m] "message"|-c COMMIT|-C COMMIT|"message"] [''|COMMITTISH|--all]`: looks for the exact identical commit message
  - `''` as the first arg (or missing) is the same as `-C HEAD`, so `git exact` is the same as `git exact -C HEAD`
  - `-m $'message'` (`-m` can be left away if unambiguous) is the exact (full) commit message to test.  Leave away the last `\n`.
  - `-c COMMIT` or `-c COMMIT` uses the commit message of `COMMIT`.  `-C` also changes `HEAD` to `COMMIT` in following:
  - `''` as the second arg is the same as `HEAD@{u}..HEAD`.  
    `HEAD@{u}..` is left away if there is no `HEAD@{u}`.  
    In the `-C` case, a `^` is appended, so `git exact -C XXX` is equivalent to `git exact -C XXX XXX@{u}..XXX^`

* `git su`: safe version of `git submodule update` like a safe `git reset --hard` on a submodule.  Missing features:
  - Create submdoules which are missing (so it behaves like `git submodule --init` for missing submodules)
  - Attach to a branch, if there is a suitable branch.
  - Automatically `git ff` tracking branches of the submodule.
  - Better reporting what is going on
* `git submodules-register`: (re-)register submodules in the `config`.
  (Fixes the case where `git reset`/`git read-tree` have `.gitmodules` in the `index` which are missing in the `config`.)

* `git isclean`: check, if everything is checked in and returns true if so.  Based on `git status --porcelain` giving no output.
* `git contained [COMMITTISH]`: check if the given `COMMITISH` (default: `HEAD`) is on a branch.  Returns true if so.
  - If `HEAD` is in detached head state and not on a branch there is the risk that the state is lost if you forget to save it.
  - So you can check with `git contained` (and possibly `git isclean`) before changing branches or doing a `git reset`
  - Note that you can access lost `HEAD`'s with `@{n}` or `@{date}` like `git log '@{1 week ago}'` etc. (see `git reflog`)

* `git fake-merge PARENT PARENT..` commit index with additional parents (without merging changes), not touching the worktree.
  - Use `git amend` or `git amend -m message` to change the commit message afterwards.
  - `git merge -s ours` is similar, but fails with a changed index, you have to stash, merge, unstash, amend.
  - `git merge -s ours PARENT PARENT..` ignores parents which are ancestors, `git fake-merge` allows them, which is important.
  - Example:  
    You merged a feature, but left out some detail.  Later on you want to make clear, that the remaining features were merged.  
    In that case you just copy the changes, stage them, and do a `git fake-merge commit commit commit` from all those parts,
    thereby documenting where the things came from.
 - A better strategy would be to create feature-merge and a feature-unmerged branches.  But quite often history is different.

* `git up`: `git status`  (this is because I always abused `cvs up` for what `git status` does today)


Not yet implemented (perhaps upcomming, so it is already registered but not implemented):

* `git ssh`: ssh key management
* `git note`: notes for branches
* `git hub`: interface to GitHUB API advanced commands


Rationale:
----------

I work on many machines and I love to edit things anywhere.  For security reasons all repository access is done via individual Deploy Keys on GitHub, so I can revoke one quickly.  L accounts on M machines with N repositories needs LxMxN SSH keys.  Go figure.

This here bundles all the everywhere needed shell helpers, allowing me to do what I want quickly everywhere.

See also http://permalink.de/tino/github


Contact:
--------

If something does not work as expected, please try to fix it yourself.  If you think your changes are interesting, please send me a pull request on GitHub.

Please note that I cannot read my mail due to SPAM.  ~~So better use my pager (URL see GitHub) wisely~~ (pager is down currently), as I will ignore messages which are errornously marked important.  Thank you for your understanding.
 

License:
--------

This Works is placed under the terms of the Copyright Less License,
see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

