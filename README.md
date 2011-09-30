**NOT READY YET**

Quick tools for GitHub
======================

These are my tools to quickly access GitHub repositories.

The tools need BASH and probably only run on Linux.

All here basically was created for my own needs.


Rationale
---------

I manage more than 10 machines and I love to edit things anywhere.

For security reasons all repository access is done via individual Deploy Keys.  As on GitHub one SSH key is for one GIT repository, creating push access to N profiles on M machines within L accounts (my named user, root, probably some service accounts) involves creation of NxMxL SSH keys.  Go figure.

My goal is to be able to set up VMs with nearly no manual intervention.  In that case I want to deploy all the common things to them, and this then needs a way to be able to easily add push access to all my GitHub repos quickly.

This here will bundle some shell helper scripts to help with all that.

More on the basics see http://permalink.de/tino/github


Configuration
-------------

There is a configuration file gitstart.conf which bundles all the settings which shall be customized.  The information in that is public, this is by purpose.  Do not put any private information in there, only public one!

If you fork this repository, edit that file and push it to your local repo to keep it handy.  That's it.


Install
-------

First time:

On GitHub clone https://github.com/hilbix/gitstart into your own repository.
```shell
git clone https://github.com/YOURPROFILE/gitstart
cd gitstart
vi gitstart.conf
./gitstart.sh
git push
```

From then on you can do:

```shell
git clone https://github.com/YOURPROFILE/gitstart
gitstart/gitstart.sh
```

If you have ideas to reduce the effort further, please let me know ;)


Files
-----

* Your local configuration file.  This is cloned from your repository:
~/.ssh/gitstart.conf

* The tools are by default installed to /usr/local/bin with a name like gitstart-*.sh

* The SSH configuration for additional GitHub specific ssh destinations
~/.ssh/config

Optional system wide configuration files:

/etc/default/gitstart.conf
/etc/gitstart.conf


Usage
-----

In bash hit gitstart- and TAB to see all tools.  Call them without parameters outside a GIT repository to see the complete usage.

Before install to clone all known repositories onto the local machine and build them:

gitstart/gitstart-build-all.sh

Basic use after install:

* `gitstart-clone.sh REPOS` clones a repository (into directory REPOS) and then creates and displays a deployment key.  `git push` works as soon as you have added the deployment key.  `git fetch` is done using HTTPS, `git push` via SSH until you call `gitstart-push.sh`.

* `gitstart-push.sh` reconfigures the current GIT repository for push access via SSH.  It will also set the fetch URL to SSH.

* `vi ~/.ssh/gitstart.conf` to alter your settings

Note that all tools are build such, that they behave reasonable if something breaks or already is present.


Notes
-----

It perhaps sounds odd that ~/.ssh/ holds gitstart.conf, but it is good to keep related information together.  Gitstart creates all public keys for SSH and adds the configuration, so storing the config there comes handy.


Contact
-------

For https://github.com/hilbix/gitstart you can contact me at https://hydra.geht.net/pager.php (please **do not** mark messages important!)

For other repositories please contact the repository owner.

