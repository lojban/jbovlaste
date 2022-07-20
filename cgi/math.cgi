#!/usr/bin/perl -I/srv/jbovlaste/current/lib

use strict;
use warnings;
use urlbase64;
use Compress::Zlib;
use File::Spec;

my $cache = "/tmp/mathimage/";

$ARGV[0] =~ s@\./@@g;

print "Content-Type: image/png\n";

sub send_image {
  my $file = shift;
  local $/ = undef;
  open(my $fh, "<", $file);
  my $image = <$fh>;
  print "Content-Length: ".length($image)."\n\n";
  print $image;
}

my $cache_file = File::Spec->catfile($cache, $ARGV[0]);

if (-f $cache_file) {
  send_image($cache_file);
  exit;
}

my $latexcode = uncompress(decode_base64($ARGV[0]));

open(my $tex, ">", "/tmp/$$.tex");

printf($tex '
\documentclass[12pt]{article}
\pagestyle{empty}
\begin{document}
\Large
\begin{displaymath}
%s
\end{displaymath}
\end{document}
', $latexcode);

close($tex);

my @commands = (
  "lambda $$.tex",
  "dvips $$.dvi -o $$.ps",
  "pstopnm < $$.ps | pnmtopng > $$.png",
  "convert -trim $$.png $cache_file",
  "rm -f $$.*",
);

chdir("/tmp");
foreach my $command (@commands) {
  print "$command\n";
  system($command." 2> /dev/null");
}

if (-f $cache_file) {
  send_image($cache_file);
} else {
  send_image(File::Spec->catfile($cache, "error"));
}
