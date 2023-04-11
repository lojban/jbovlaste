package SimpleLaTeX;

# This package deals with LaTeX expressions in the word definitions.
# This is mostly used for $x_{1}$ sort of things.
#
# $x_{1}$ type stuff is converted to HTML.
#
# Once this is done, if there are more than one remaining $ in the text,
# it is run through latex2html for display.

sub interpret {
    use File::Temp qw/ tempfile tempdir /;
    use utf8;

    my $InputText = shift();
    my $OrigInputText = $InputText;

    # See if we need to do anything at all by counting $s.
    if( scalar( $InputText =~ tr/$/$/ ) >= 2)
    {
	my $LastInputText="";

	while( $LastInputText ne $InputText )
	{
	    $LastInputText = $InputText;

	    if( $InputText =~ s/\$([a-z0-9_={}]*)\$/####/ )
	    {
		my $InputTextPart = $1;

		## Handle subscripts
		# Match x_{15}
		$InputTextPart =~ s/(\S+)_\{(\S+)\}/$1<sub>$2<\/sub>/g;
		# Match x_1
		$InputTextPart =~ s/(\S+)_(\S)/$1<sub>$2<\/sub>/g;

		# Match _{15}
		$InputTextPart =~ s/_\{(\S+)\}/<sub>$1<\/sub>/g;
		# Match _1
		$InputTextPart =~ s/_(\S)/<sub>$1<\/sub>/g;

		$InputText =~ s/####/$InputTextPart/;
	    }

	}
    }

    # See if we need to do anything more by counting $s.
    if( scalar( $InputText =~ tr/$/$/ ) >= 2)
    {
	# Here we run latex2html on the string to deal with the more
	# complicated stuff.

	# Can't carry the <sub> stuff through.
	$InputText=$OrigInputText;

	# Make a temp directory and file.
	mkdir "/tmp/jbovlaste_export/";
	my $dir = tempdir( DIR => "/tmp/jbovlaste_export/", CLEANUP => 1 );
	my ($fh, $filename) = tempfile( DIR => $dir, SUFFIX => ".tex" );

	open(TMP, ">", $filename) or return "Couldn't open temporary file $filename for writing.\n";
        binmode TMP, ':utf8';
	
	print TMP "\\documentclass{letter}\n\\begin{document}\n";
	# Write the input text out.
	print TMP "$InputText\n";
	print TMP "\\end{document}\n";

	close( TMP );

	# Run latex2html.
	`/usr/bin/latex2html -no_navigation -info 0 -addres 0 -dir $dir -html_version 4.0,math -no_subdir $filename 2>&1 >/dev/null`;

	# Get the latex2html generated file's name.
	$htmlfilename=$filename;
	$htmlfilename =~ s/.tex$/.html/;

	open(TMP2, "<$htmlfilename") or return "Couldn't open temporary html file $htmlfilename; this is supposed to hold output from latex2html, so probably that failed; check your definition for unbalanced dollar signs or other wierd characters.\n";
        binmode TMP2, ':utf8';

	# Snarf the data.
	my $tmpout=join( "", <TMP2>);

	close(TMP2);

	# Re-write the image links.
	$dir =~ s!/tmp!!;
	$tmpout =~ s/.*<BODY[^>]*>//s;
	$tmpout =~ s/<BR[^>]*><HR[^>]*>.*//s;
	$tmpout =~ s/SRC="/SRC="$dir\//gs;

	$InputText=$tmpout;
    } else {
        # If we *didn't* run latex2html, strip out escapes we might
        # have added in mini() in lib/Wiki.pm
        $InputText =~ s/\\{/{/g;
        $InputText =~ s/\\}/}/g;
    }

    return $InputText;
}

1;
