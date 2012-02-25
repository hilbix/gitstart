This is preliminary.  I am not completely ready with this yet.

How to recover a lost commit
============================

The basics behind the alias `git lost-branches`.

If you suddenly do not see your last commit again, as you used `git branch -f`, don't panic:

- `git fsck --lost-found` to "find" your "lost" objects
- `git co <object>` to switch to your object
- `git branch <name>` to give them a name, such that they become "known" again

It's easy if you know how to.  Note that you should be able to see your commit history timeline with `git reflog` as well.  But then it's not that easy to spot which were lost and recover.


Try it:
-------

```bash
mkdir tmp
git init
echo hello > test
git add test
git commit -m 1
git branch a
echo world > test
git commit -am 2
git branch b
git checkout a
echo get lost > test
git commit -am 3
git branch -f b
# Now the old b is lost
git fsck --lost-found
ls -al .git/lost-found/commit/
```

Let's recover by assigning them names, automagically:

```bash
for a in .git/lost-found/commit; do git checkout "$a"; git branch "lost-`basename "$a"`"; done
```

This way you see your lost branches in `git branch -v` easily.

