package utils;

use strict;
use utf8;
use Unicode::String qw(utf8);

use File::Basename;
use File::Spec;
use File::Slurp;

use Crypt::CBC;

my $util_dir = dirname(__FILE__);
my $secret_file = File::Spec->catfile($util_dir, "crypt.secret");
my $python_dir = File::Spec->catdir($util_dir, "..", "python");
my $vlatai_path = File::Spec->catfile($python_dir, "camxes-py", "vlatai.py");

my $VLATAI = File::Spec->rel2abs($vlatai_path);

my $cipher = Crypt::CBC->new( -key    => read_file($secret_file),
                              -cipher => 'Blowfish'
                             );

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

    return $cipher->encrypt($str);
}

sub decrypt {
    my $str = shift;

    eval {
        $str = $cipher->decrypt($str);
    };
    if ($@) {
        # Caught error: decryption failed
        # This is presumably because $str was not actually encrypted.
        # It doesn't matter what we return, as long as it's not the original $str.
        # This is because the old implementation was no encryption at all,
        # and it was used to "encrypt" cookies. These cookies must be regenerated,
        # so the code calling decrypt() must realize that they are invalid,
        # and if we returned the original $str then the caller would continue
        # believing that it was encrypted and we "decrypted" it by doing nothing.
        return "error";
    } else {
        return $str;
    }
}

sub vlatai {
    my $valsi = shift;
    unless(length($valsi)) {
	return "nalvla";
    }
    my $type = run_vlatai($valsi);
    # ASSUME: only running vlatai on words that couldn't be looked up in db,
    #         so any morphological gismu or cmavo are "experimental"
    if ($type eq "gismu") {
	return "experimental gismu";
    }
    if($type eq "cmavo") {
	return "experimental cmavo";
    }
    return $type;
}

sub run_vlatai {
    my $valsi = shift;
    my $tmp = $/;
    undef $/; # slurp mode
    my $safevalsi = $valsi;
    $safevalsi =~ s/[^\'\w, ]//g; # NOTE: spaces are significant
    $safevalsi =~ s/\'/\\\'/g;
    if (open(VLATAI, "$VLATAI $safevalsi|")) {
      my $type = <VLATAI>;
      close(VLATAI);
      $/ = $tmp;
      chomp $type;
      return $type || "nalvla";
    }
    $/ = $tmp;
    warn "Failed to run vlatai($VLATAI): $!";
    return "nalvla";
}

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
  my ($addresslist, $subject, $contents, $username ) = @_;
  $subject =~ s/"/'/g;

  # Add a sort of header to the subject
  if( defined($username) ) {
    $subject = "[jvsw] $subject -- By $username";
  } else {
    $subject = "[jvsw] $subject -- By $username";
  }

# print "<pre>subj: $subject</pre>\n";

  use Email::MIME;
  use Email::Sender::Simple qw(sendmail);
  use Email::Simple;
  use Email::Simple::Creator;

  my $email = Email::MIME->create(
    attributes => {
      charset      => 'UTF-8',
    },
    header_str => [ 
      To            => join(', ', @$addresslist ),
      'Reply-To'    => 'webmaster@lojban.org',
      From          => 'webmaster@lojban.org',
      Subject       => $subject,
    ],

    body => $contents,
  );

  # send to explicit Bcc address
  sendmail($email, { to => 'jbovlaste-admin@lojban.org', from => 'webmaster@lojban.org' });
  # and then send as normal
  sendmail($email);

  use Data::Dumper;
  my $text=$email->as_string;
# print "<pre>".Dumper($text)."</pre>\n";
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
