#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $DIR/db.sh

rm -rf /srv/jbovlaste/words/
mkdir -p /srv/jbovlaste/words/

# Used by the JVS Tiki plugin hack to decide if a word exists

psql -h $PGHOST -p $PGPORT -c "select natlangwords.word, languages.tag from natlangwords, languages where natlangwords.langid = languages.langid;" -t -U jbovlaste jbovlaste | /bin/sed -e 's/  *|  */:/g' -e 's/^  *//' >/srv/jbovlaste/words/nlw

psql -h $PGHOST -p $PGPORT -c "select word from valsi;" -t -U jbovlaste jbovlaste | /bin/sed -e 's/  *|  */:/g' -e 's/^  *//' >/srv/jbovlaste/words/valsi

wc -l /srv/jbovlaste/words/*
