#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $DIR/db.sh

pg_dump -h $PGHOST -p $PGPORT -U jbovlaste -s jbovlaste >/srv/jbovlaste/current/help/schema.txt
