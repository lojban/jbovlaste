#!/bin/sh
#
# Used to seach for natlang words with both a default and non-default
# definition.
#

echo "Bad Data: valsi without definitions."
/usr/bin/psql -h localhost -d jbovlaste -U jbovlaste <<EOF
select word, username from valsi v, users u where v.userid=u.userid and valsiid not in (select valsiid from definitions);
EOF

echo "Bad Data: natlang words never used."
/usr/bin/psql -h localhost -d jbovlaste -U jbovlaste <<EOF
select word, username, l.realname from natlangwords n, users u, languages l where n.userid=u.userid and n.langid=l.langid and wordid not in (select natlangwordid from keywordmapping);
EOF

echo "Poor Data: Definitions with no keywords/gloss words."
/usr/bin/psql -h localhost -d jbovlaste -U jbovlaste <<EOF
select definition, username, l.realname from definitions d, users u, languages l where d.userid=u.userid and d.langid=l.langid and definitionid not in (select definitionid from keywordmapping);
EOF

echo "Deleting Bad Data."
/usr/bin/psql -h localhost -d jbovlaste -U jbovlaste <<EOF
delete from valsi where valsiid not in (select valsiid from definitions) and wordid != 0;

delete from natlangwordvotes where natlangwordid in (
select wordid from natlangwords where wordid not in (select natlangwordid from keywordmapping) and wordid != 0
);

delete from natlangwords where wordid not in (select natlangwordid from keywordmapping) and wordid != 0;
EOF
