#!/bin/sh

psql -t -c 'select email from users;' | \
grep -v '^ *$' | \
sed 's/^ *\([^ ]*\).*$/\1 : |ECHOPOST|/' > /tmp/jvs_list
