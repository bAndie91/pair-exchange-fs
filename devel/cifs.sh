#!/bin/bash

if [ -z "$AUTOFS_USER" ]
then
	AUTOFS_USER=$1
fi
if [ -z "$AUTOFS_UID" ]
then
	AUTOFS_UID=`getent passwd "$AUTOFS_USER" | cut -d: -f3`
fi
if [ -z "$AUTOFS_HOME" ]
then
	AUTOFS_HOME=`getent passwd "$AUTOFS_USER" | cut -d: -f6`
fi
if [ -z "$CIFS_SERVER" ]
then
	CIFS_SERVER=`basename "$PWD"`
fi

set -u

user=$AUTOFS_USER
cifsroot=$PWD/$user
credfile=$AUTOFS_HOME/.smb/cifs.$CIFS_SERVER.cred


if ! getent group users | cut -d: -f4 | tr , "\n" | grep -qx $user
then
	echo "$user is not member of users." >&2
	exit 1
fi

install -o $user -g root -m 0500 -d "$cifsroot"


echo -n "-fstype=cifs,guest,username=$user,credentials=$credfile,noperm "

smbclient -U $user -N -A "$credfile" -L "$CIFS_SERVER" -g | \
while IFS='|' read share_type share_name share_comment
do
        if [ "$share_type" = Disk ]
        then
                echo -n "/$share_name ://$CIFS_SERVER/$share_name "
        fi
done

echo
exit 0
