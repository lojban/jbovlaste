#!/usr/bin/perl -T
#
# Name   : Dict
# Purpose: perl script cgi program to submit dict queries.
# Author : Doug L. Hoffman (hoffman@shopthenet.net)
# Created: Thu Aug 14 09:51:28 1997 by hoffman
# Revised: Mon Sep  3 22:44:52 2001 by bam@miranda.org
#
# This perl script both generates the www-browser form and accepts the results
# of submitting the form. The search is transmitted to a central machine
# and the results are interpreted and reposted for the user.
#
#  $Log: Dict,v $
#  Revision 1.11  1998/03/30 17:33:26  hoffman
#  added text of query to the web page title line.
#
#  Revision 1.10  1998/02/23 17:46:04  hoffman
#  Fixed problem with word list anchors caused by changes to the "exact"
#  resopnse.
#
#  Revision 1.9  1998/02/23 16:41:30  hoffman
#  Made "exact" return list of words, not definitions.
#
#  Revision 1.8  1998/02/20 16:00:01  hoffman
#  gave the generated page(s) a general facelift, changed internal processing
#  to use the short database name, not the description, and then spent time
#  fixing various bugs that the name change caused. The server calls to fetch
#  the search and database options have been combined into one.
#
#  Revision 1.7  1998/02/19 15:10:26  hoffman
#  Rik's updated version.
#
#  Revision 1.6  1997/11/12 16:07:50  hoffman
#  Added link to copyright info.
#
#  Revision 1.5  1997/10/01 17:50:58  hoffman
#  Fixed some of the field edits for Rik.
#
#  Revision 1.4  1997/10/01 13:56:52  hoffman
#  fixed problem with ()'s
#
#  Revision 1.3  1997/08/17 20:48:04  hoffman
#  added link to dict.org home page
#
#  Revision 1.2  1997/08/17 20:07:37  hoffman
#  Fixed imbedded blank sequence query scanning.
#
#

# Setup is minimal.
#
#	You have to redefine at most the first few lines below
#
#	$ReturnUrl is the url of this file. It should be changed to reflect
#		the new location.

# ---------- Configuration variables

use Data::Dumper;
use File::Temp qw/ tempfile /;

use strict;
use warnings;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

$ENV{'PATH'} = "/usr/bin:/bin";

my $Debug        = 0;

my $Pgm          = "lookup.pl";
my $ReturnUrl    = "/$Pgm";
my $bin          = "/srv/jbovlaste/lookup";

#my $CRInfo   = "$ReturnUrl?Form=$Pgm".
#    "1&Query=00-database-info&Strategy=*&Database=*";
#my $SInfo   = "$ReturnUrl?Form=$Pgm". "4";

my $CRInfo	= "https://mw.lojban.org/papri/LLG_Web_Copyright_License";

my $SInfo	= "https://mw.lojban.org/papri/nuzba/en";

my $Dict    = "/usr/bin/dict -h dict.lojban.org";
#my $DictAlt = "/usr/local/bin/dict -h dega.cs.unc.edu";
my $Counter = "/usr/local/etc/Counter/data/$Pgm.dat";
my $Count   = "/Count.cgi";
#my $Background = "/gifs/grayback.jpg";
my $Background = "";
my $Heading1= "The Logical Language Group: Online Dictionary Query";
my $Heading2= '<a href="http://www.lojban.org/">The Logical Language Group</a> Online&nbsp;Dictionary&nbsp;Query';
my $Counter1= "<img src=\"$Count?sh=0|df=$Pgm.dat\" alt=\"\">";
my $Counter2= "<img src=\"$Count?sh=0|df=total.dat\" alt=\"\">";
# my $Counter1= "";
# my $Counter2= "";
my $WebMaster="<a href=\"mailto:webmaster\@lojban.org\">webmaster\@lojban.org</a>";

my (%in, $Error, %Choices, %Db, %Dbr, %St, $in, $flag,
$triedbackup, $DictAlt, @Fields, @ReqFields, $wordlist, $matchdb, $line,
);
$Error="";

# --- display stuff

##########################################################################
#
# Driving Program
#
#########################################################################

&init;			# init globals
&ReadParse;		# read stdin


#
#
# If there is no standard input, this the the users first request to see
# the page. Return a decent looking page. Otherwise, you have work to do.
#

if (! defined($in{"Form"}) || $in{"Form"} eq "") {
    $in{"Database"} = "en<->jbo";
    $in{"Strategy"} = "*";
    print &PrintHeader();
    &SendBeginning;
    &SendForm1;
    &SendEnding;
}
elsif (defined($in{"Form"}) && $in{"Form"} eq ($Pgm . '1')) {
    print &PrintHeader();
    &SendBeginning;
    &StripFields;		# clean up user entered data.
    &CheckFields;		# Make sure all required data are there.
    &SendForm1;
    if ($Error eq "") {
	&SendListing;
    }
    &SendEnding;
}
elsif (defined($in{"Form"}) && $in{"Form"} eq ($Pgm . '2')) {
    $in{"Strategy"} = "*";
    print &PrintHeader();
    &SendBeginning;
    &StripFields;		# clean up user entered data.
    &CheckFields;		# Make sure all required data are there.
    &SendForm1;
    if ($Error eq "") {
	&SendListing;
    }
    &SendEnding;
}
elsif (defined($in{"Form"}) && $in{"Form"} eq ($Pgm . '3')) {
    $in{"Strategy"} = "";
    $in{"Query"} = "";
    print &PrintHeader();
    &SendBeginning;
    &StripFields;		# clean up user entered data.
#    &CheckFields;		# Make sure all required data are there.
    &SendForm1;
    if ($Error eq "") {
	&SendListing;
    }
    &SendEnding;
}
elsif (defined($in{"Form"}) && $in{"Form"} eq ($Pgm . '4')) {
    $in{"Strategy"} = "";
    $in{"Query"} = "";
    print &PrintHeader();
    &SendBeginning;
    &StripFields;		# clean up user entered data.
#    &CheckFields;		# Make sure all required data are there.
    &SendForm1;
    if ($Error eq "") {
	$in{"Query"} = "Server";
	&SendListing;
    }
    &SendEnding;
}
else {
    print &PrintHeader();
    &SendBeginning;
    print "<br><hr>Error, invalid syntax: $in<hr><br>\n";
    &SendForm1;			# wtfo? send form anyway.
    &SendEnding;
}	

#############################################################################
#
# --------------- Init global variables 
#

sub init {
    my( $name, $desc);
    my $flag = 0;
    my $triedbackup = 0;
#
# ----- List of  database and search strategy options
#
# For each option, a comma separated string of the acceptable values
#
    $Choices{"Database"} = "Any";
    
    %Db = ("Any" => "*"
	   #,"First match" => "!"  jbovlaste no workie
	   );
    
    %Dbr = ("*" => "Any"
	   #,"First match" => "!"  jbovlaste no workie
	   );
    
    $Choices{"Strategy"} = "Return Definitions";
    
    %St = ("Return Definitions" => "*");

    # ----- suck in the database/strategy names from the server

    my $cachefile = "/srv/jbovlaste/current/lookup/dict.cache.pl";
    my @results = stat($cachefile);
    if(-T _ && -r _ && ($results[9]+3600)>time())
    {
	my $cachedata = require $cachefile;
	%Choices = %{ $cachedata->{'Choices'} };
	%Db  = %{ $cachedata->{'Db'} };
	%Dbr = %{ $cachedata->{'Dbr'} };
	%St  = %{ $cachedata->{'St'} };
    }
    else
    {
        my ($tmpfh, $tmpfname) = tempfile( DIR => '/srv/jbovlaste/current/lookup' );
	open(IN,"$Dict -DS 2>$tmpfname |") || die "$Pgm: can't execute /usr/bin/dict\n";
      restartopen:
	<IN>;
      LOOP:
	while (<IN>) {
	    ++$flag;
	    chomp;
	    last LOOP if  /^Strategies/;
	    /^\s+(\S+)\s+(.*?)\s*$/;
	    ($name,$desc) = ($1, $2);
	    $Choices{"Database"} .= "\t$desc";
	    $Db{$desc} = $name;
	    ($Dbr{$name} = $desc) =~ tr/ /+/; # reverse lookup index
	}
	while (<IN>) {
	    ++$flag;
	    chomp;
	    /^\s([^ ]+) (.*)$/;
	    ($name,$desc) = ($1, $2);
	    $Choices{"Strategy"} .= "\t$desc";
	    $St{$desc} = $name;
	}
	close( IN );
        errprint( $tmpfname );
	if (!$flag) {
	    if (!$triedbackup && $DictAlt) {
		++$triedbackup;
                my ($tmpfh, $tmpfname) = tempfile( DIR => '/srv/jbovlaste/current/lookup' );
    		open(IN,"$DictAlt -DS 2>$tmpfname |") ||
		    die "$Pgm: can't execute /usr/bin/dict\n";
		goto restartopen;
	    }
	}

	use Data::Dumper;
	open(CACHE, '>', $cachefile);
	print CACHE Dumper({ Choices => \%Choices, Db => \%Db, Dbr => \%Dbr, St => \%St });
	close(CACHE);
    }

#
# The regular expression contraints:
#    
    @Fields = ("Query", "Database", "Strategy", "Server");
    
    @ReqFields =  ("Query");
}

# ---------- Update the counter
#
sub UpdateCounter {
    my ($count);
    if ($Counter ne "") {
	if (!(open(CT,"<$Counter"))) {
	    print "$Pgm: Couldn't open $Counter<p>\n";
	    return;
	}
	$count = <CT>;
	close CT;
	$count++;
	if (!(open(CT,">$Counter"))) {
	    print "Couldn't write $Counter<p>\n";
	    return;
	}
	print CT $count;
	close CT;
    }
}


# ---------- Strip fields
#
# change tabs and stuff to blanks, strip any leading/trailing blanks.
#

sub StripFields {
  foreach my $x (@Fields) {
    if( defined $in{$x} ) {
      $in{$x} =~ y/{};/() /;        #  ensure no {, },",", or ";".
        $in{$x} =~ y/\n\r\f\t\e/     /s;  # ensure newlines or cr's.
        #$in{$x} =~ s/\'/\'\'/g;	
        # Shell meta-chars:
        #$in{$x} =~ s/\*/\\\*/;
        #$in{$x} =~ s/\?/\\\?/;
        $in{$x} =~ s/^\s*//;	
        $in{$x} =~ s/\s*$//;	
        $in{$x} =~ s/\s+/ /g;	
    }
  }
}

#
# ---------- Check that the required fields are all present.
#

sub CheckFields {
    $Error = "";
    foreach my $x (@ReqFields) {
	if ($in{$x} eq "") {
	    $Error = $x;
	    return;
	}
    }
}


#############################################################################
#
# ---------- Send the html form for the editing of a record
#

sub SendForm1 {

# ----- send the header
#
    my($q) = $in{"Query"} || '';

#<!-- hidden counter -->
#$Counter1
#<!-- hidden counter -->
#$Counter2

    print <<EOF;
<p>There are specific tools that make searching this database easier:</p>
<p><a href="https://la-lojban.github.io/sutysisku/en/">la sutysisku dictionary</a>, an offline enabled web app</p>
<p><a href="http://vlasisku.lojban.org/">la vlasisku</a> search engine for the Lojban dictionary</p>
<form method="GET" action="$ReturnUrl">
    <input type="hidden" name="Form" value="${Pgm}1">
    <center>
	<table><tr><td align="right">
	<b>Query string:</b></td><td>
	<input type="text" name="Query" size="40" value="$q">
        <br></td></tr><tr><td align="right">
        <b>Search type:</b></td><td align="left">
        <select name="Strategy">
EOF
    foreach my $x (split(/\t/,$Choices{"Strategy"})) {
	print "        <option value=\"$St{$x}\"";
	if (defined($in{"Strategy"}) && defined($St{$x})){
          if ($in{"Strategy"} eq $St{$x}) {
	    print " selected";
          }
	}
	print ">$x\n";
    }
    print <<EOF2;
        </select>
	<br></td></tr><tr><td align="right">
        <b>Database:</b></td><td>
        <select name="Database">
EOF2
    my @sorted_dbs =
      sort {lc $a cmp lc $b}
      (split(/\t/, $Choices{"Database"}));
    foreach my $x (@sorted_dbs) {
	print "        <option value=\"$Db{$x}\"";
	if (defined($in{"Database"}) && $in{"Database"} eq $Db{$x}) {
	    print " selected";
	}
	print ">$x\n";
    }
    print <<EOF3;
        </select>
	</td></tr></table>
        <input type="submit" name="submit" value="Submit query">
        <input type="reset" value="Reset form">
	<!--
	<p>
	Definition not available or out of date?
	    <a href="http://www.dict.org/file.html">Contribute to FILE</a>.
	-->
	<br>
	<a href="$CRInfo">Database copyright information</a>
	<br>
	<a href="$SInfo">Server information</a>
    </center>
	<p>To improve the quality of results, jbovlaste search does not return words with insufficient votes. To qualify to be returned in search results, a proposed lujvo is required to have received a vote in favor in both directions: for instance, in English to Lojban and in Lojban to English.</p>
	<p>In addition, due to it being a very technically hard problem, full text searching (that is, searching of definitions rather than just keywords) is not available at this time.</p>
</form>
<hr>
EOF3
}  


#############################################################################
#
# ---------- Send the html form for the search listing results
#

sub SendListing {
  my( $command, $d, $s, $q);
  my( $i, $x );
  my $flag=0;
  my $triedbackup = 0;

  # ----- add the hidden counter.

#    print "\n<!-- hidden counter -->\n";
#    print "<img src=\"/bin/Count.cgi?sh=0|df=$Pgm.dat\">\n";

#    &UpdateCounter;

  # ---------- report

  use Encode;
  $in{'Query'} = decode("UTF-8", $in{'Query'});

  if ($in{'Query'} =~ /^(['\w .]+|)$/) {
    $q = "$1";
  } else {
    warn ("TAINTED DATA for query SENT BY $ENV{'REMOTE_ADDR'}: ". $in{'Query'} .": $!");
    $q = ""; # successful match did not occur
  }

  # print "<pre>orig: --".$in{'Query'}."--</pre>\n";
  # print "<pre>checked: --".$q."--</pre>\n";

  if( $q eq "" ) {
    print "<hr><p>\n";
    print "<b>Your query is invalid.</b>\n";
    print "<p><hr>\n";
    return;
  }

  if ($in{'Database'} =~ /^([\w .<>*-]+|)$/) {
    $d = "$1";
  } else {
    warn ("TAINTED DATA for database SENT BY $ENV{'REMOTE_ADDR'}: $d: $!");
    $d = ""; # successful match did not occur
  }

  if( $q eq "" ) {
    print "<hr><p>\n";
    print "<b>Your query is invalid.</b>\n";
    print "<p><hr>\n";
    return;
  }

  $s = $in{"Strategy"};

  my $remote_host = "";
  if( defined $ENV{'REMOTE_HOST'} ) {
    $remote_host = $ENV{'REMOTE_HOST'};
    if ($remote_host =~ /^([-\w.]+|)$/) {
      $remote_host = "$1";
    } else {
      warn ("TAINTED DATA for remote_host SENT BY $ENV{'REMOTE_ADDR'}: $remote_host: $!");
      $remote_host = ""; # successful match did not occur
    }
  }
  my $user_agent = "";
  if( defined $ENV{'HTTP_USER_AGENT'} ) {
    $user_agent = $ENV{'HTTP_USER_AGENT'};
    if ($user_agent =~ /^([:+,\(\);\/-\@0-9\s\w.]+)$/) {
      $user_agent = "$1";
    } else {
      warn ("TAINTED DATA for user_agent SENT BY $ENV{'REMOTE_ADDR'}: $user_agent: $!");
      $user_agent = ""; # successful match did not occur
    }
  }

  $command = "--client \"$remote_host $user_agent\" ";
  if ($s eq "" && $q eq "") {
    $command .= "-i '$d'";
  } elsif ($s eq "" && $q eq "Server") {
    $command .= "-I";
  } else {
    if ($d ne "" ) {
      $command .= "-d '$d'";
    }
    $wordlist = 0;
    if ($s eq '*') {
      $command .= " \"". $q . "\"";
    }
#	elsif ($s eq 'exact') {
#	    $command .= " -s exact \"". $q ."\"";
#	}
    else {
      $s =~ /(\*|regexp|suffix|exact|substring|rafsi|prefix)/;
      $s = $1;
      $command .= " -s $s -m \"". $q ."\"";
    }
  }

  print "$Dict $command <p>\n" if ($Debug);

  my ($tmpfh, $tmpfname) = tempfile( DIR => '/srv/jbovlaste/current/lookup' );
  if (!open(IN,"$Dict $command 2>$tmpfname |")) {
    print "<hr><p>\n";
    print "<b>Backend database engine temporarily unavailable:\n";
    print " please try again later</b>\n";
    print "<p><hr>\n";
    return;
  }

  if ($s eq "" && $q eq "") {
    my($tmp) = &lx($Dbr{$d});
    print "<b>From <a href=\"$ReturnUrl?Form=${Pgm}3&Database=$d\">$tmp<\/a>:</b>\n";
  }
  print "<pre>";
restart: 
  my $fromd = undef;
  while(<IN>) {
    if( $Debug ) {
      print "IN: $_</pre><pre>";
    }
    ++$flag;
    if (/^From/) {
      if (/\[.*\]/) {
        s/^From\s*(.*)\s*\[(.*)\]\s*:.*$/From <a href=\"$ReturnUrl?Form=${Pgm}3&Database=$2\">$1<\/a>:/; # " 
          $fromd = $2;
      }
      print "</pre><b>$_</b><pre>\n";
    }
    elsif (/^\d+ /) {
      print "</pre><b>$_</b><pre>";
    }
    elsif (/^No definitions/) {
      print "</pre><b>$_</b><pre>\n";
    }
    elsif (/^No matches/) {
      print "</pre><b>$_</b><pre>\n";
    }
    # "Match substrings" and the like hit this branch and the next one
    elsif (/^(\S+) /) {
      ($matchdb, $line) = split(/:/, $_, 2);
      $line = &anchor( $matchdb, $line);
      print "<b>$matchdb:</b>$line";
      $wordlist = 1;
    }
    elsif ($wordlist && (/^  (\S+) /)) {
      $line = &anchor( $matchdb, $_);
      print $line;
    }
    else {
      if (/(ftp|http):\/\/[^\s\)\}]*\}/) {
        s,((ftp|http)://[^\s\)\}]*)\},}<a href="$1">$1</a>,g;
    } else {
      s,((ftp|http)://[^\s\)\}]*),<a href="$1">$1</a>,g;
    }
    # s,(\s){([^}\s][^}]*)},$1.'<a href="'.$ReturnUrl.'?Form='.$Pgm.'2&Database=*&Query='.&xl($2).'">'.$2.'</a>',ge;
#if (/(\s){([^}\s][^}]*)(\n)$/) {
  #    $savefirst = $2;
  #}

if(defined $fromd && $fromd =~ /jbo->/)
{
  s!(^\s+Word: |){([^}]+)}!
  sprintf('%s<a href="%s?Form=%s2&Database=*&Query=%s">%s</a>%s',
      $1, $ReturnUrl, $Pgm, &xl($2), $2,
      length($1) ?
      sprintf(' <a href="/dict/%s">[jbovlaste]</a>',
        $2) : '')
  !seg;
  } elsif(defined $fromd && $fromd =~ /(\S+)->jbo/) {
    my $natlang = $1;
    s!(^\s*){([^}]+)}!
    sprintf('%s<a href="%s?Form=%s2&Database=*&Query=%s">%s</a>%s',
        $1, $ReturnUrl, $Pgm, &xl($2), $2,
        length($1) ?
        sprintf(' <a href="/natlang/%s/%s">[jbovlaste]</a>',
          $natlang, $2) : '')
    !seg;
    }

#'<a href="'.$ReturnUrl.'?Form='.$Pgm.'2&Database=*&Query='.&xl($2).'">'.$2.'</a>'

	    #s,^(\s*)([^}]*)},$1.'<a href="'.$ReturnUrl.'?Form='.$Pgm.'2&Database=*&Query='.&xl($savefirst).&xl(' ').&xl($2).'">'.$2.'</a>',e;
	    
	    s/\t/ /g;
	    print;
	}
    }
    print "</pre>\n";
    close( IN );
    my $iserr = errprint( $tmpfname );

    if (!$flag && $iserr ) {
        if (!$triedbackup && $DictAlt) {
		++$triedbackup;
    		print "$DictAlt $command <p>\n" if ($Debug);

                my ($tmpfh, $tmpfname) = tempfile( DIR => '/srv/jbovlaste/current/lookup' );
                if (open(IN,"$DictAlt $command 2>$tmpfname |")) {
			print "</pre><b>Using backup server...</b>\n";
			print "<hr><p><pre>\n";
			goto restart;
		}
	}
        print "<b>\n";
        print "Backend database engine error: please try again later\n";
        print "</b><p>";
    }
    print "<hr>\n";
}

sub xl { my($tmp) = $_[0]; $tmp =~ s/(\W)/sprintf('%%%02x',ord($1))/ge; $tmp; }
sub lx { my($tmp) = $_[0]; $tmp =~ s/%([a-fA-F0-9]{2})/chr($1)/ge; $tmp; }

sub errprint {
  my( $fname ) = @_;

  local $/ = undef;
  open FILE, $fname or die "Couldn't open file: $!";
  binmode FILE;
  $_ = <FILE>;
  close FILE;

  unlink($fname);

  if (/^No definitions/) {
    print "</pre><b>$_</b><pre>\n";
    return 0;
  }
  elsif (/^No matches/) {
    print "</pre><b>$_</b><pre>\n";
    return 0;
  }
  elsif( $Debug )
  {
    print "<pre>Errors found running dict: $_</pre>";
    return 1;
  }
}
sub anchor {
    my( $dbname, $line) = @_;
    my( $x, $y, $db, $new_line);

    my $odd = 1;
    foreach $x  (split("\"", $line)) {
	if ($odd) {
	    $x =~ s/ (\S+)/ <a href="$ReturnUrl?Form=${Pgm}2&Database=$dbname&Query=$1">$1<\/a>/g;
	    $new_line .= $x;
	    $odd = 0;
	}
	else {
	    ($y = $x) =~ tr/ /+/;
	    $new_line .= "<a href=\"$ReturnUrl?Form=${Pgm}2&Database=$dbname&Query=$y\">\"$x\"<\/a>";
	    $odd = 1;
	}
    }

    return $new_line;
}

#
# ----- Common beginning.
#
sub SendBeginning {
    my ($title);
    
    $title = $Heading1;
    if ($in{'Query'}) {
	$title .= "- $in{'Query'}";
    }
    
    print <<EOF;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<head>
<title>$title</title>
</head>
<body background="$Background">
<center>
    <table border=0>
<tr><td align="center">
<font size="+3"><b>$Heading2</b></font>
</td></tr></table>
</center>
<hr size=3>
EOF
}

#
# ----- Common ending.
#
sub SendEnding {

    print <<EOF;
<center>
    <font size="-1">
	Questions or comments about this site?
	Contact $WebMaster
        <br />
        <!--Submit corrections or error reports via <a href="/">jbovlaste</a>.-->
    </font>
</center>
</body>
</html>
EOF
}


#############################################################################
#
# --------------- Library Stuff
#

# Perl Routines to Manipulate CGI input
# S.E.Brenner@bioc.cam.ac.uk
# $Header: /data/httpd/html/Internal/bin/RCS/Dict,v 1.11 1998/03/30 17:33:26 hoffman Exp $ #
# Copyright 1993 Steven E. Brenner  
# Unpublished work.
# Permission granted to use and modify this library so long as the
# copyright above is maintained, modifications are documented, and
# credit is given for any use of the library.

# ReadParse
# Reads in GET or POST data, converts it to unescaped text, and puts
# one key=value in each member of the list "@in"
# Also creates key/value pairs in %in, using '\0' to separate multiple
# selections

# If a variable-glob parameter (e.g., *cgi_input) is passed to ReadParse,
# information is stored there, rather than in $in, @in, and %in.
sub ReadParse {
  if (@_) {
    my @in = @_;
  }

  my ($i, $loc, $key, $val);
	my ($fp);
  # Read in text
  if ($ENV{'REQUEST_METHOD'} eq "GET") {
    $in = $ENV{'QUERY_STRING'};
  } elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
    #for ($i = 0; $i < $ENV{'CONTENT_LENGTH'}; $i++) {
    #  $in .= getc;
    #}
	my $ntoread = $ENV{'CONTENT_LENGTH'};
	my $in = "";
	my $n = 60;
	if ($ntoread < $n) {
		$n = $ntoread;
	}
	while ($ntoread) {
                my $inn;
		my $x = read(STDIN,$inn,$n);
		$in = $in . $inn;
		$ntoread = $ntoread - $x;
		if ($ntoread < $n) {
			$n = $ntoread;
		}
	}
	#read(STDIN,$in,$ENV{'CONTENT_LENGTH'});
  } 

  my @in = split(/&/,$in);

  foreach my $i (0 .. $#in) {
    # Convert plus's to spaces
    $in[$i] =~ s/\+/ /g;

    # Convert %XX from hex numbers to alphanumeric
    $in[$i] =~ s/%(..)/pack("U",hex($1))/ge;

    # Split into key and value.
    my $loc = index($in[$i],"=");
    my $key = substr($in[$i],0,$loc);
    my $val = substr($in[$i],$loc+1);
    print "in: $key\n";
    $in{$key} .= '\0' if (defined($in{$key})); # \0 is the multiple separator
    $in{$key} .= $val;

  }

  return 1; # just for fun
}

# PrintHeader
# Returns the magic line which tells WWW that we're an HTML document

sub PrintHeader {
  return "Content-Type: text/html; charset=utf-8\n\n";
}

