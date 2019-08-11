#!/bin/bash
#
# A variant of git-alias which allows you to print aliases
# the sane way, not rubbish like with git-alias from git-extras.
#
# Note that, unlike git-alias from git-extras,
# this here neither allows to define or override aliases.
# How do I create --local aliases with extra's git-alias anyway?
#
# For today I have not implemented search as well.
# Use `less` for this.  It's easy.

export LC_ALL=C

# Only list for now

git config --null --get-regexp ^alias |
awk -vWIDTH="`tput cols`" '
BEGIN	{
	RS=sprintf("%c", 0);
	}
	{
	sub(/^alias\./,"");
	c=$1;
	n[c] = c;
	l	= length(c);
	if (l<15 && max<l) max=l;
	sub(/^[^[:space:]]*[[:space:]]/,"");
	a[c] = $0;
	}
END	{
	k = asort(n);
	for (i=0; ++i<=k; )
		{
		b=n[i];
		c=a[b];
		indent(b,c);
		}
	}

function indent(b,s, p,w,c,n,o,x,k)
{
n	= max + 8-((max+1)%8);
c = sprintf("%*s#", n, " ");
p = sprintf("%-*s", n+1, b ":");
if (length(b)>n)
  {
    printf("%s: \\\n", b);
    p = c;
  }

w = WIDTH - n - 2;
if (w<40)
  w = 40;

s = s "\n";
do
	{
	o	= s;
	gsub(/\n.*$/,"",o);
	for (k=w;; k--)
		{
		o	= substr(o,1,k);
		x	= o;
		# this overestimates TABs a bit
		gsub(/\t/,"        ",x);
		if (length(x)<=w || k<3)
			break;
		}
	# make room for \\ when it is needed
	n	= length(o);
	if (n>=k && (substr(s,n+1,1)!="\n" || o ~ /\\$/))
	  o	= substr(o,1,--n);
	if (substr(s,n+1,1)!="\n" || o ~ /\\$/)
	  o	= o "\\";
	else
	  n++;
	printf("%s %s\n", p, o);
	s = substr(s,n+1);
	p = c;
	} while (s!="");
}
' |

less -X -S -F -R

