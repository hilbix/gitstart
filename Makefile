# I love make

.PHONY: all
all:	install

.PHONY: install
install:
	./fix-bashrc.sh
	./aliases.sh
	mkdir -p "$(HOME)/bin" && for a in git-*.sh COMMIT; do [ ".`readlink -e "$$a"`" = ".`readlink -e "$(HOME)/bin/$$a"`" ] || ln -s -v --backup=t "`readlink -e "$$a"`" "$(HOME)/bin/"; done
	ln -sf "`readlink -e gitstart-add.sh`" "$(HOME)/.ssh/.add"
#	Actually ~/.ssh/.add is a hack until `git ssh` is ready.
#	Sadly following fails utterly with blanks or LF in path:
#		ln -sf `readlink -e git-*.sh` "$(HOME)/bin/"

.PHONY: clean distclean
clean distclean:
	@echo dummy target: $@

