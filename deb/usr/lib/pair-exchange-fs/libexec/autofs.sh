#!/bin/bash

declare -a Users
declare -A UsersAssoc

LogMissingCommonFilnames=no
IndicatorFilename=.pair-exchange-fs

sortnames()
{
	echo -e "$1\n$2" | sort | { read a; read b; echo $a-$b; }
}

user_list=`getent group users | cut -f4 -d:`
Users=(${user_list//,/ })

for user in "${Users[@]}"
do
	UsersAssoc[$user]=1
done


if [ -z "$1" ]
then
	for user in "${Users[@]}"
	do
		echo $user
	done
	echo "$IndicatorFilename"
	exit 0
fi

if [ "$1" = "$IndicatorFilename" ]
then
	echo "-fstype=none /$IndicatorFilename :/dev/null"
	exit 0
fi

user1=$1
storedir=`dirname "$PWD"`/store

if [ -z "${UsersAssoc[$user1]}" ]
then
	if ! grep -Exq '\.git|refs|objects|HEAD' <<<"$user1" || [ $LogMissingCommonFilnames = yes ]
	then
		echo "$user1 is not member of users." >&2
	fi
	exit 1
fi

echo -n "-fstype=bindfs,realistic-permissions,chgrp-deny,create-as-user,perms=u+rwD:u-s:g-s:o-rwx "
for user2 in "${Users[@]}"
do
	if [ "$user1" = "$user2" ]
	then
		continue
	fi
	storename=`sortnames $user1 $user2`
	storepath=$storedir/$storename
	install -d "$storepath" -o root -g root -m 0700
	install -d "$PWD/$user1" -o $user1 -g root -m 0500
	echo -n "/$user2 -mirror=$user1:$user2 :$storepath "
done
echo ''
exit 0

