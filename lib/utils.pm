package utils;

use strict;
use utf8;
use Unicode::String qw(utf8);

sub armorutf8inhtml {
    my $utf8 = utf8(shift());
    my @chars = $utf8->unpack;
    my @html = map { (chr($_)=~/\w/)?chr($_):sprintf("&#%i;",$_) } @chars;
    return join('',@html);
}

sub armorurl {
    return armorutf8forurl(shift());
#  my $url = shift;
#  $url =~ s/([^A-Za-z0-9\-\_\$\.\!\*\?\(\)])/sprintf("%%%02x",ord($1))/ge;
#  return $url;
}

sub encrypt {
    my $str = shift;

    return $str;
}

sub decrypt {
    my $str = shift;

    return $str;
}

sub grokzei {
    my ($valsi) = @_;

    # grok the first word
    if ($valsi =~ /([\w\']+) zei (.*)/) {
    	my ($part, $rest) = ($1, $2);

	# zo can't be used with zei
	return "nalvla" if $part eq "zo";

	# make sure vlatai groks the first word, then
	# let it grok the part after the zei (which will
	# recurse back into this function if it hits another
	# zei-formed lujvo
	return "nalvla" if vlatai($part) eq "nalvla";
	return "nalvla" if vlatai($rest) eq "nalvla";

	# it seems to be a correct lujvo
	return "lujvo";
    }

    # mi na jimpe
    return "nalvla";
}

sub vlatai {
    my $valsi = shift;
    unless(length($valsi)) {
	return "nalvla";
    }
    my(@tmp) = ($|,$/);
    $| = 1; undef $/;
    my $safevalsi = $valsi;

    # handle zei lujvo (vlatai doesn't grok it for us)
    return grokzei($valsi) if $valsi =~ /.*zei.*/;

    $safevalsi =~ s/[^\'\w,]//g;
    $safevalsi =~ s/\'/\\\'/g;
    open(VLATAI, "vlatai $safevalsi|");
    my $result = <VLATAI>;
    $result =~ s/\s+$//g;
    close(VLATAI);
    ($|,$/) = @tmp;
    my($vlataivalsi,$type,$extra,@crap) = split/\s*:\s*/,$result;
    if($vlataivalsi ne $valsi) {
	return "nalvla";
    }
    if(($type eq "gismu") && $extra !~ /\s/) {
	return "experimental gismu";
    }
    if($type eq "cmavo(s)") {
	if($extra =~ /\s/) {
	    return "cmavo cluster";
	} else {
	    return "experimental cmavo";
	}
    }
    if($extra !~ /\s/) {
	if($type eq "lujvo" || $type eq "lujvo (with cultural rafsi)") {
	    return "lujvo";
	}
	if($type =~ /^fu'ivla/) {
	    return "fu'ivla";
	}
	if($type eq "cmene") {
	    return "cmene";
	}
    }
    return "nalvla";
}

my %type =
  ('1' => 'gismu',
   '2' => 'cmavo',
   '3' => 'lujvo',
   '4' => 'fu\'ivla',
   '5' => 'cmene',

   '6' => 'cmavo cluster',

   '7' => 'experimental gismu',
   '8' => 'experimental cmavo'
  );

my %revtype = reverse %type;

sub processkeywordlisting {
  my $textblob = shift;
  my @keywords = (split/\s*\n\s*/, $textblob);
  for(my $i=0; $i<=$#keywords; $i++) {
    unless(length($keywords[$i])) {
      $keywords[$i] = undef;
    }
    $keywords[$i] =~ s/^\s*(.+?)\s*$/$1/g;
    $keywords[$i] = [split/\s*;\s*/,$keywords[$i],2];
    $keywords[$i]->[1] ||= undef;
  }
  return @keywords;
}

sub armorutf8forurl {
    my $utf8 = shift();
    my @bytes = unpack("C*",$utf8);
    my @htmlbytes = map { (chr($_)=~/^[A-Za-z0-9\-\_\$\.\!\*\?\(\)]$/)?chr($_):sprintf("%%%02x",$_) } @bytes;
    return join('',@htmlbytes);
}

# This is used in dict/dhandler.
sub generatenatlangwordlink {
  my($lang, $ref, $wordid, $bg) = @_;
  my $format = '<a href="../natlang/%s/%s%s">%s%s</a>';
  my $bgstring = $bg ? "?bg=1;wordidarg=$wordid" : "";
  my $str =
    sprintf($format,
	    $lang, armorutf8forurl($ref->[0]), $bgstring,
            $ref->[0], length($ref->[1])?(" ; ".$ref->[1]):"");
  return $str;
}

sub generatemissingwordlink {
  my($lang,$word,$meaning) = @_;
  return
    sprintf('<a href="../natlang/add.html?lang=%s;word=%s%s">%s%s</a>',
            $lang,
            armorutf8forurl($word),
            defined($meaning)?sprintf(';meaning=%s',armorutf8forurl($meaning)):"",
	    $word,
	    defined($meaning)?" in the sense of \"$meaning\"":"");
}

sub sendemail {
    use Encode qw/encode decode/;

    my ($address, $subject, $contents, $username ) = @_;
    $subject =~ s/"/'/g;

    # Add a sort of header to the subject
    if( defined($username) ) {
	$subject = "[jvs-watch] Per $username: $subject";
    } else {
	$subject = "[jvs-watch] Per unknown user: $subject";
    }

    # Be a nice mail person
    my $encsubj = encode("MIME-Header", $subject);

    open( MAILX, qq{| /usr/bin/mailx -b jbovlaste-admin\@lojban.org -a "Content-type: text/plain;charset=UTF-8" -s "$encsubj" $address});

    print MAILX $contents;

    close( MAILX );
}

sub mydiff {
    use Algorithm::Diff;

    my ( $seq1, $seq2 ) = @_;

    my $diff = Algorithm::Diff->new( $seq1, $seq2 );

    my $rettext;

    $diff->Base( 1 );   # Return line numbers, not indices
	while(  $diff->Next()  ) {
	    next   if  $diff->Same();
	    my $sep = '\n';
	    if(  ! $diff->Items(2)  ) {
		$rettext .= sprintf "%d,%dd%d\n",
			$diff->Get(qw( Min1 Max1 Max2 ));
	    } elsif(  ! $diff->Items(1)  ) {
		$rettext .= sprintf "%da%d,%d\n",
			$diff->Get(qw( Max1 Min2 Max2 ));
	    } else {
		$sep = "---\n";
		$rettext .= sprintf "%d,%dc%d,%d\n",
			$diff->Get(qw( Min1 Max1 Min2 Max2 ));
	    }
	    $rettext .= "< $_\n"   for  $diff->Items(1);
	    $rettext .= $sep;
	    $rettext .= "> $_\n"   for  $diff->Items(2);
	}

    return $rettext;
}

1;
