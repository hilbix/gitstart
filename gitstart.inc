#

fullname()
{
getent passwd "$USER" | awk -F: '{sub(/,.*?/,"",$5); print $5}'
}

