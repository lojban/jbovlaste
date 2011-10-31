#!/bin/sh

if [ ! "$2" ]
then
	echo "Give valsi from and to, like: $0 meltrita mletritra, to change meltrita to mletritra."
	exit 1
fi

id=$(psql -t -U jbovlaste jbovlaste -c "select valsiid from valsi where word='$1';" | head -1)

if [ ! "$id" ]
then
	echo "No id found for $1."
	exit 1
fi

echo "Id for $1 found: $id.  Setting $id to $2."

psql -t -U jbovlaste jbovlaste -c "update valsi set word='$2' where valsiid=$id;"

psql -t -U jbovlaste jbovlaste -c "select * from valsi where valsiid=$id;"
