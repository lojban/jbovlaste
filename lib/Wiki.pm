# Converts Wiki-compatible plain text to HTML

## Copyright 2001 John Cowan.  All rights reserved.
## 
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
## 
##     * Redistributions of source code must retain the above copyright
##     notice, this list of conditions and the following disclaimer.
##
##     * Redistributions in binary form must reproduce the above copyright
##     notice, this list of conditions and the following disclaimer in the
##     documentation and/or other materials provided with the distribution.
## 
##     * Neither the name of John Cowan nor the names of his
##     contributors may be used to endorse or promote products derived from
##     this software without specific prior written permission.
## 
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
## IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
## THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
## PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS
## BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
## OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
## THE POSSIBILITY OF SUCH DAMAGE.


package Wiki;
use strict;
use urlbase64;
use Compress::Zlib;
use HTML::Mason;
use Data::Dumper;
use SimpleLaTeX;

use utils;

sub get_placeword {
    my ($c, $defid) = @_;
    my $dbh = \$HTML::Mason::Commands::dbh;
    my ($query, $row);

    if( $defid )
    {
	$query = $$dbh->prepare("select nlw.word from natlangwords nlw,
		keywordmapping p where ((nlw.wordid = p.natlangwordid) and
		    (p.place = $c) and (p.definitionid = $defid))");
		$query->execute();
		$row = $query->fetchrow_hashref;
    }

    return length($row->{'word'}) ? $row->{'word'} : "unknown_place_$c";
}

#####
# This procedure handles jbovlaste word references of the form
# {word:args}.
#####
sub interp_vlaspec {
    my ($word, $vlaspec, $langtag) = @_;
    my $dbh = \$HTML::Mason::Commands::dbh;
    my ($i, $c);
    my ($out, $query, $row);
    my $valsiid;
    my ($glossword, $definition);

    $langtag = "en" unless defined $langtag;

# read crud we need from the database
    $query = $$dbh->prepare("select valsiid from valsi where word=?");
    $query->execute( $word );
    $row = $query->fetchrow_hashref;
    if (!defined($row->{'valsiid'})) {
	return "<a href=\"../dict/$word\">$word (not in database)</a>";
    }
    $valsiid = $row->{'valsiid'};

# get the best guess definition
    $query = $$dbh->prepare("select d.definition, d.definitionid from
	    valsibestguesses bg, definitions d, languages l
	    where ((l.tag = ?) and (d.definitionid = bg.definitionid)
		and (bg.langid = l.langid) and (bg.valsiid = $valsiid))");
    $query->execute($langtag);
    $row = $query->fetchrow_hashref;

    $definition = length($row->{'definition'}) ? $row->{'definition'}
    : "unknown_definition";

# query for the gloss word
# there can be more than one gloss word for a definition, but we just
# use the first one we get for 'g' flags.
    my $defid = $row->{'definitionid'};
    if( $defid )
    {
	$query = $$dbh->prepare("select nlw.word, nlw.wordid, nlw.langid from
		natlangwords nlw, keywordmapping kw where
		((nlw.wordid = kw.natlangwordid) and (kw.definitionid = $defid) and
		 (kw.place = 0))
		");
	$query->execute();
	$row = $query->fetchrow_hashref;
    }

    $glossword = length($row->{'word'}) ? $row->{'word'} : "unknown_gloss";
    my $glosswordid = length($row->{'wordid'}) ? $row->{'wordid'} : 0;
    my $langid = length($row->{'langid'}) ? $row->{'langid'} : 0;

# use this hash so we don't look up places more than once
    my (%places);

    $out = "";
    for ($i = 0; $i < length $vlaspec; $i++) {
	$c = substr $vlaspec, $i, 1;

	if ($c eq 'g') {		# keyword gloss
	    if( $glossword ne "unknown_gloss" )
	    {
		$out .= "<a href=\"../natlang/$langtag/" . utils::armorurl($glossword) .
		    "?bg=1;wordidarg=$glosswordid\">$glossword</a>";
	    } else {
		$out .= $glossword
	    }
	} elsif ($c eq 'w') {	# show the word
	    $out .= "<a href=\"../dict/" . utils::armorurl($word) .
		"\">$word</a>";
	} elsif ($c eq 'd') {	# definition
	    $out .= $definition;
	} elsif ($c =~ /[1-9]/) {	# place keyword
	    if (length($places{$c})) {
		my $placeid=$$dbh->selectrow_array("SELECT wordid FROM
			natlangwords WHERE word=? AND langid=$langid\n", undef,
			$places{$c});
		$out .= "<a href=\"../natlang/$langtag/" . utils::armorurl($places{$c}) .
		    "?bg=1;wordidarg=$placeid\">$places{$c}</a>";
		next;
	    }

	    my $dat = get_placeword($c, $defid);
	    $places{$c} = $dat;
	    if( $dat eq "unknown_place_$c" )
	    {
		$out .= $dat;
	    } else {
		my $placeid=$$dbh->selectrow_array("SELECT wordid FROM
			natlangwords WHERE word=? AND langid=$langid\n",
			undef, $places{$c});
		$out .= "<a href=\"../natlang/$langtag/" . utils::armorurl($dat) .
		    "?bg=1;wordidarg=$placeid\">$dat</a>";
	    }	
	} elsif ($c eq 'p') {	# all keywords, comma seperated
	    my ($i, $have);

	    $have = 0;
	    for ($i = '1'; $i < '9'; $i++) {
		my $word = get_placeword($i, $defid);

		last if $word eq "unknown_place_$i";

		$out .= ", " if $have;
		$have = 1;

		my $placeid=$$dbh->selectrow_array("SELECT wordid FROM
			natlangwords WHERE word=? AND langid=$langid\n", undef, $word);
		$out .= "<a href=\"../natlang/$langtag/" . utils::armorurl($word) .
		    "?bg=1;wordidarg=$placeid\">$word</a>";
	    }

	    $out .= "no_place_keywords" if $i eq '0';
	} else {
# pass through unchanged
	    $out .= $c;
	}
    }

    my $dollarcount = $out =~ tr/$//;
    if( $dollarcount >= 2 )
    {
	$out = SimpleLaTeX::interpret($out);
    }

    return $out;
}

sub wordreferencegenerate {
    my($word,$alt,$lang,$args) = @_;
    my $alttxt;
    my $dbh = \$HTML::Mason::Commands::dbh;

    if (defined($alt)) {
	$alttxt = $alt;
    } else {
	$alttxt = $word;
    }

    if ( defined($args) ) {
	return interp_vlaspec($word, $args, $lang);
    }

    $lang = "en" unless defined $lang;
    my $langid = $$dbh->selectrow_array( "SELECT langid FROM languages WHERE tag=?", undef, $lang);

    my $valsiid=$$dbh->selectrow_array("SELECT valsiid FROM valsi WHERE word=?", undef, $word );

    if( $valsiid != 0 )
    {
	return sprintf( "<a href=\"../dict/%s?bg=1;langidarg=%s\">%s</a>",
		utils::armorurl($word), $langid,  $alttxt
		);
    } else {
	return sprintf( "<a href=\"../dict/%s?bg=1;langidarg=%s\">Word %s not found in database.</a>",
		utils::armorurl($word), $langid,  $alttxt
		);
    }
}

sub nlwordrefgenerate
{
    my $dbh = \$HTML::Mason::Commands::dbh;
    my( $word, $lang, $bg, $meaning) = @_;

    $meaning = $meaning ? $meaning : undef;

    $lang = $lang ? $lang : 'en' ;

# If we've been told to provide a non-best-guess link...	
    if( $bg )
    {
	my $wordid=$$dbh->selectrow_array("SELECT wordid FROM
		natlangwords WHERE word=?
		AND (meaning=? OR (? IS NULL AND meaning IS NULL))
		AND langid= (SELECT langid FROM languages WHERE tag=?)",
		undef, $word, $meaning, $meaning, $lang );

	return "<a href=\"../natlang/$lang/" .
	    utils::armorurl($word) .
	    "?bg=1;wordidarg=$wordid\">$word</a>";
    } else {
	return "<a href=\"../natlang/$lang/" .
	    utils::armorurl($word) . "\">$word</a>";
    }
}

# Accepts a line of plain text, interprets inline markup, answers HTML
sub inline {
    local $_ = shift;
    my $lang = shift;
    my $dollarcount;

    s/&/\&amp;/g;
    s/</\&lt;/g;

    $dollarcount = tr/$//;
    if( $dollarcount >= 2 )
    {
	$_ = SimpleLaTeX::interpret($_);
    }

    s%'''(.*?)'''%<b><i>$1</i></b>%g;
    s%''(.*?)''%<i>$1</i>%g;
    s%__(.*?)__%<b>$1</b>%g;

# External links.
# [link!]
    s%(?<!\[)\[([^\[\]\|]*)?\!\]%<a href="$1">$1</a>%g;
# [link!alt]
    s%(?<!\[)\[([^\[\]\|]*)?\!([^\[\]\|]*)?\]%<a href="$1">$2</a>%g;

# images; for admin use only
    s%(?<!\[)\[([^\[\]\|]*?\.(?:gif|png|jpe?g))\]%<img src="$1" border="0" \/>%g;

# jbovlaste {natlang!lang} links
# {natlangword!meaning!}
    s%(?<!\{)\{([^\{\}\:]*)?\!([^\!\{\}\:]*)\!\}%&nlwordrefgenerate($1,$lang,1,$2)%ge;
# {natlangword!meaning!lang}
    s%(?<!\{)\{([^\{\}\:]*)?\!([^\!\{\}\:]*)\!([^\{\}\:]*)?\}%&nlwordrefgenerate($1,$3,1,$2)%ge;
# {natlangword!}
    s%(?<!\{)\{([^\{\}\:]*)?\!\}%&nlwordrefgenerate($1,$lang,0)%ge;
# {natlangword!lang}
    s%(?<!\{)\{([^\{\}\:]*)?\!([^\{\}\:]*)?\}%&nlwordrefgenerate($1,$2,0)%ge;

# jbovlaste {valsi} links
# {valsi:args||lang}
# No {valsi:args|alt|lang} because having an alt over-ride the args defeats the purpose of the args.
    s%(?<!\{)\{([^\{\}\:]*)?\:([^\{\}\|\:]+)?\|\|([^\{\}\|]+)?\}%&wordreferencegenerate( $1, undef, $3, $2)%ge;
# {valsi:args}
    s%(?<!\{)\{([^\{\}\:]*)?\:([^\{\}\:]+)?\}%&wordreferencegenerate( $1, undef, $lang, $2 )%ge;
# {valsi||lang}
    s%(?<!\{)\{([^\{\}\|]*)?\|\|([^\{\}\|]+)?\}%&wordreferencegenerate( $1, undef, $2, undef)%ge;
# {valsi|alt|lang}
    s%(?<!\{)\{([^\{\}\|]*)?\|([^\{\}\|]*)?\|([^\{\}\|]*)?\}%&wordreferencegenerate( $1, $2, $3, undef)%ge;
# {valsi|alt}
    s%(?<!\{)\{([^\{\}\|]*)?\|([^\{\}\|]*)?\}%&wordreferencegenerate( $1, $2, $lang, undef )%ge;
# {valsi}
    s%(?<!\{)\{([^\{\}]*)?\}%&wordreferencegenerate( $1, undef, $lang, undef )%ge;

# Allow literal []s and {}s
    s#\[\[([^[])#\[$1#g;
    s#\]\]([^]])#\]$1#g;
    s#\{\{([^{])#\{$1#g;
	s#\}\}([^}])#\}$1#g;

	s#%%%#<br />#g;

	return $_;
}

# Answer the appropriate string to change from $omode of depth $odepth
# to $nmode of depth $ndepth.
sub chgmode {
    my ($omode, $odepth, $nmode, $ndepth) = @_;
    if ($omode eq $nmode) {
	my $change = $ndepth - $odepth;
	if ($change >= 0) {
	    return "<$nmode>" x $change;
	}
	else {
	    return "</$nmode>" x -$change;
	}
    }
    else {
	return "</$omode>" x $odepth .
	    "<$nmode>" x $ndepth;
    }
}

# Accepts a Wiki-style-plain-text string, answers HTML equivalent.
sub interpret {
    my ($text, $lang, $jbovlastedir, $noformat) = @_;

    open(FILE, ">$jbovlastedir/../../mason-data-dir/wikirender.log");  

    my @lines = split("\n", $text);
    my $size = @lines;
    my $mode = "";
    my $depth = 0;
    for (my $i = 0; $i < $size; $i++) {
	local $_ = inline($lines[$i], $lang);
	print FILE $_;
	if (/^=/) {
	    $_ = chgmode($mode, $depth, "pre", 1) . substr($_,1);
	    $mode = "pre";
	    $depth = 1;
	}
	elsif (/^(\*+)(.*)/) {
	    my $ndepth = length($1);
	    $_ = chgmode($mode, $depth, "ul", $ndepth) . 
		"<li>$2</li>";
	    $mode = "ul";
	    $depth = $ndepth;
	}
	elsif (/^(#+)(.*)/) {
	    my $ndepth = length($1);
	    $_ = chgmode($mode, $depth, "ol", $ndepth) . 
		"<li>$2</li>";
	    $mode = "ol";
	    $depth = $ndepth;
	}
	elsif (/^----+/) {
# Remove the actual rule command
	    s/^----+//;
	    $_ = chgmode($mode, $depth, "", 0) . "<hr />" . $_;
	    $mode = "";
	    $depth = 0;
	}
	elsif (/^;(.*?):(.*)/) {
	    $_ = chgmode($mode, $depth, "dl", 1) .
		"<dt>$1</dt><dd>$2</dd>";
	    $mode = "dl";
	    $depth = 1;
	}
	elsif (/^(!+)(.*)/) {
	    my $level = 4 - length($1);
	    $_ = chgmode($mode, $depth, "", 0) .
		"<h$level>$2</h$level>";
	    $mode = "";
	    $depth = 0;
	}
	elsif (/^\|(.*)/) {
	    $_ = chgmode($mode, $depth, "table", 1);
	    $_ .= "<table>" unless $mode eq "table";
	    $mode = "table";
	    $depth = 1;
	    my @tmp = split/\s*\|\s*/,$1;
	    @tmp = map { "<td>$_</td>" } @tmp;
	    $_ .= join("","<tr>",@tmp,"</tr>");
	}
	elsif (/^$/) {
	    if ($mode eq "p" or $mode eq "pre") {
		$_ = chgmode($mode, $depth, "", 0);
		$mode = "";
		$depth = 0;
	    }
	}
	else {
	    if( $noformat )
	    {
		$_ = chgmode($mode, $depth, "", 0) . $_;
		$mode = "";
		$depth = 0;
	    } else {
		$_ = chgmode($mode, $depth, "p", 1) . $_;
		$mode = "p";
		$depth = 1;
	    }
	}
	$lines[$i] = $_;
	print FILE $_;
    }
    if($size>0) {
	$lines[$size-1] .= chgmode($mode, $depth, "", 0);
	$text = join("\n", @lines);
	$text .= "\n" if $text;
    }
    close(FILE);
    return $text;
}

# Teensy bit of interpret, for Notes fields.
sub mini {
    my ($text, $lang, $noformat) = @_;

    $_=$text;

    my $dollarcount = tr/$//;
    if( $dollarcount >= 2 )
    {
	$_ = SimpleLaTeX::interpret($_);
    }

# {word}
    s%(?<!\{)\{([^\{\}]*)?\}%&wordreferencegenerate( $1, undef, $lang, undef)%ge;

    return $_;
}

1;

__END__

# Debugging code.
package MAIN;
my $text;
$/ = undef;
$text = <>;
print Wiki::interpret($text);
