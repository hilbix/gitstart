# I love make

all:	install

install:
	./fix-bashrc.sh
	./aliases.sh
	mkdir -p "$(HOME)/bin" && for a in git-*.sh; do ln -vsf "`readlink -e "$$a"`" "$(HOME)/bin/"; done
	ln -sf "`readlink -e gitstart-add.sh`" "$(HOME)/.ssh/.add"
#	Sadly following fails utterly with blanks or LF in path:
#		ln -sf `readlink -e git-*.sh` "$(HOME)/bin/"

