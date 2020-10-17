#!/bin/sh

cd /tmp
wget --quiet http://jbovlaste.lojban.org/emails.html
cat /tmp/emails.html | sed '1,/==START HERE==/d' | \
  sed '/==END HERE==/,$d' | sed 's/  *//g' | \
  grep -v jbovlaste-admin@lojban.org | \
  grep -v webmaster@lojban.org | \
  sort | uniq > /tmp/jvs_emails.txt

echo -e '\njbovlaste-archive@lojban.org' | sed '/^ *$/d' >> /tmp/jvs_emails.txt

cat /tmp/jvs_emails.txt

users="/tmp/jvs_emails.txt"
list="jbovlaste"

/usr/lib/mailman/bin/remove_members -n --all "$list"

/usr/lib/mailman/bin/add_members -r $users -w n -a n "$list"

rm /tmp/jvs_emails.txt
rm /tmp/emails.html*
