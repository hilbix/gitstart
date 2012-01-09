#!/bin/bash

RC="$HOME/.bashrc"
TMP="$RC.git.tmp"

add()
{
fgrep -qx "$1" "$TMP" || echo "$1" >> "$TMP"
}

# Inserts the `$(__git_ps1 "(%s)")` right before the `$` on the PS1 prompt
sed -e '/__git_ps1/b' -e 's|\(^[[:space:]]*PS1='\''.*\)\(\\\$ '\''[[:space:]]*\)$|\1\$(__git_ps1 "(%s)")\2|' "$RC" > "$TMP"

grep -w PS1 "$TMP" ||
cat <<'EOF' >> "$TMP"
[ -z "$PS1" ] || PS1="`echo "$PS1" | sed -e '/__git_ps1/b' -e 's|\(\\\\\\\$[[:space:]]*\)$|\$(__git_ps1 "(%s)")\1|'`"
EOF

# Append some proper settings for __git_ps1
add "export GIT_PS1_SHOWDIRTYSTATE=yes"
add "export GIT_PS1_SHOWUNTRACKEDFILES=yes"

# Install the changes
if	cmp -s "$RC" "$TMP"
then
	rm -f "$TMP"
else
	mv -v --backup=t "$TMP" "$RC"
fi

