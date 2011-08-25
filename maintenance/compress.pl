#!/usr/bin/perl

use DBI;
use Compress::Zlib;
use MIME::Base64;

my $dbh = DBI->connect("dbi:Pg:dbname=jbovlaste;host=morji",
		       "jbovlaste", "makfa");
$dbh->begin_work;
$sth = $dbh->prepare("SELECT content FROM pages WHERE pagename=? AND version=? AND langId=?");
$sth->execute(@ARGV);

my $row = $sth->fetchrow_hashref;

$sth = $dbh->prepare("UPDATE pages SET compressed='true', content=? WHERE pagename=? AND version=? AND langId=?");
$sth->execute(encode_base64(compress($row->{'content'}),''), @ARGV);

$dbh->commit;
