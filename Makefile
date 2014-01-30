# I love make

all:	install

install:
	./fix-bashrc.sh
	./aliases.sh
	ln -sf "`readlink -e gitstart-add.sh`" "$(HOME)/.ssh/.add"
	mkdir -p "$(HOME)/bin"
	ln -sf "`readlink -e git-carry.sh`" "$(HOME)/bin/"
	ln -sf "`readlink -e git-alias.sh`" "$(HOME)/bin/"

