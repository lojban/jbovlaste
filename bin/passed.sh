#!/bin/sh

if [ ! "$1" -o ! "$2" ]
then
	echo "Try again."
	exit
fi

version=$1
baseline=$2

echo "jbovlaste $version was updated
by copying $baseline to /home/jbovlaste/current" | mailx rlpowell -s "/home/jbovlaste/current updated"

cd $baseline
find . -type f \! -name '*,D' | cpio -pv /home/jbovlaste/current/
chmod u+w /home/jbovlaste/current/
