#!/bin/sh

psql -U jbovlaste -d jbovlaste -t -c 'select email from users where length(trim(password))>20;' | \
grep -v '^ *$' | \
sed 's/^ *\([^ ]*\).*$/\1 : |ECHOPOST|/' > /tmp/jvs_list
