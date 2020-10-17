#!/bin/sh

# Just helpful.
chmod -R u+w /home/jbovlaste/current >/dev/null 2>&1
chmod go-rwx bin backups

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $DIR/db.sh

# Bacup every few hours, but only name it based on today's date, so we only
# keep one per day
fname=/home/jbovlaste/backups/dump.`date +%Y%b%d`

pg_dump -C -U jbovlaste -h $PGHOST -p $PGPORT -f $fname
rm -f $fname.gz
gzip -9 $fname


#####
## RT is in MySQL now
####
##
## ## Get RT while we're at it.
## export PGPASSWORD=Nsp4sswd
## 
## # Bacup every few hours, but only name it based on today's date, so we only
## # keep one per day
## fname=/home/jbovlaste/backups/rt.dump.`date +%Y%b%d`
## 
## pg_dump -C -U rt -f $fname
## rm -f $fname.gz
## gzip -9 $fname
