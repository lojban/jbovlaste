#!/usr/bin/perl -I/var/www/jbovlaste/current/lib

use urlbase64;
use Compress::Zlib;

my $cache = "/tmp/mathimage/";

$ARGV[0] =~ s@\./@@g;

print "Content-Type: image/png\n";

if(-f $cache.$ARGV[0]) {
 undef $/;
 open(FILE,$cache.$ARGV[0]);
 my $image = <FILE>;
 print "Content-Length: ".length($image)."\n\n";
 print $image;
 close(FILE);
 exit;
}

my $latexcode = uncompress(decode_base64($ARGV[0]));

open(LATEX,">/tmp/$$.tex");

printf(LATEX '
\documentclass[12pt]{article}
\pagestyle{empty}
\begin{document}
\Large
\begin{displaymath}
%s
\end{displaymath}
\end{document}
', $latexcode);

my @commands =
("lambda $$.tex",
 "dvips $$.dvi -o $$.ps",
 "pstopnm < $$.ps | pnmtopng > $$.png",
 "convert -trim $$.png $cache".$ARGV[0],
 "rm -f $$.*");

foreach my $command (@commands) {
    print "$command\n";
    system("cd /tmp ; ".$command." 2> /dev/null");
}

if(-f $cache.$ARGV[0]) {
  undef $/;
  open(FILE,$cache.$ARGV[0]);
  my $image = <FILE>;
  print "Content-Length: ".length($image)."\n\n";
  print $image;
  close(FILE);
} else {
  undef $/;
  open(FILE,$cache."error");
  my $image = <FILE>;
  print "Content-Length: ".length($image)."\n\n";
  print $image;
  close(FILE);
}
