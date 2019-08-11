# I love make

.PHONY: all
all:	install

.PHONY: install
install:
	./fix-bashrc.sh
	./aliases.sh
	mkdir -p "$$HOME/bin"
	for a in git-*.sh; do b="`basename -- "$$a" .sh`"; ./link-or-copy.sh "$$a" "$$HOME/bin/$$b" || break; done
	for a in COMMIT link-or-copy.sh; do ./link-or-copy.sh "$$a" "$$HOME/bin/$$a" || break; done
	./link-or-copy.sh gitstart-add.sh "$$HOME/.ssh/.add"
	./link-or-copy.sh gitstart-ls.sh "$$HOME/.ssh/.list"
#	Actually ~/.ssh/.add is a hack until `git ssh` is ready.
#	Sadly following fails utterly with blanks or LF in path:
#		ln -sf `readlink -e git-*.sh` "$$HOME/bin/"

.PHONY: clean distclean
clean distclean:
	@echo dummy target: $@

