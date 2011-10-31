#!/bin/sh

# Used by the JVS Tiki plugin hack to decide if a word exists

/usr/bin/psql -c "select natlangwords.word, languages.tag from natlangwords, languages where natlangwords.langid = languages.langid;" -t -U jbovlaste jbovlaste | /bin/sed -e 's/  *|  */:/g' -e 's/^  *//' >/var/tmp/nlw

/usr/bin/psql -c "select word from valsi;" -t -U jbovlaste jbovlaste | /bin/sed -e 's/  *|  */:/g' -e 's/^  *//' >/var/tmp/valsi
