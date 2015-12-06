#!/bin/bash

export LC_ALL=C

# Only list for now

git config --get-regexp ^alias |
awk -vWIDTH="`tput cols`" '
	{
	sub(/^alias\./,"");
	a[$1]=$0;
	n[$1] = $1;
	if (max<length($1)) max=length($1);
	}
END	{
	k = asort(n);
	for (i=0; ++i<=k; )
		{
		b=n[i];
		c=a[b];
		sub(/^[^[:space:]]*[[:space:]]/,"",c);
		indent(b,c);
		}
	}

function indent(b,s, p,w,c)
{
w = WIDTH - max - 3;
if (w<40)
  w = 40;

p = sprintf("%-*s", max, b);
c = sprintf("%*s", max, "");
for (;;)
	{
	if (length(s)<=w)
		{
		print p "  " s;
		return;
		}
	printf("%s  %s\\\n", p, substr(s,1,w-1));
	s = substr(s,w);
	p = c;
	}
}
' |

less -X -S -F -R

