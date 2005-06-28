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
    } else {
	return $InputText;
    }

    # See if we need to do anything more by counting $s.
    if( scalar( $InputText =~ tr/$/$/ ) >= 2)
    {
	# Here we run latex2html on the string to deal with the more
	# complicated stuff.

	# Can't carry the <sub> stuff through.
	$InputText=$OrigInputText;

	# Make a temp directory and file.
	my $dir = tempdir( DIR => "/home/www/tmp/", CLEANUP => 1 );
	my ($fh, $filename) = tempfile( DIR => $dir, SUFFIX => ".tex" );

	open(TMP, ">$filename") or return "Couldn't open a temporary file; check your definition for unbalanced dollar signs or other wierd characters.\n";
	
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

	open(TMP2, "<$htmlfilename") or return "Couldn't open temporary html file; check your definition for unbalanced dollar signs or other wierd characters.\n";

	# Snarf the data.
	my $tmpout=join( "", <TMP2>);

	close(TMP2);

	# Re-write the image links.
	$dir =~ s!/home/www!!;
	$tmpout =~ s/.*<BODY[^>]*>//s;
	$tmpout =~ s/<BR[^>]*><HR[^>]*>.*//s;
	$tmpout =~ s/SRC="/SRC="http:\/\/www.digitalkingdom.org$dir\//gs;

	$InputText=$tmpout;
    }

    return $InputText;
}

1;
