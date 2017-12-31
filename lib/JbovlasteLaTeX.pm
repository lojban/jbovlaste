package JbovlasteLaTeX;

use utf8;

use Exporter qw(import);
@EXPORT_OK = qw( generate_latex );

our $JAPANESE = 'ja';
our $GUASPI   = 'art-guaspi';

sub generate_latex {
    my ($dbh, $lang) = @_;

    my $langrealname = $dbh->selectrow_array("SELECT realname FROM languages WHERE tag=?", undef, $lang);
    utf8::decode($langrealname);
    my $escapedlang = escapeall($langrealname);

    my $title = generate_title($escapedlang);
    my $chapters = generate_chapters($dbh, $lang, $escapedlang);

    latex_header($title, $lang) .
        "\n" .
        $chapters .
        "\n" .
        latex_footer();
}

sub escapeall {
    my $term = shift;
    $term =~ s/\\/\\textbackslash{}/g;
    $term =~ s/(?<!\\textbackslash)([{])/\\$1/g;
    $term =~ s/(?<!\\textbackslash\{)([}])/\\$1/g;
    $term =~ s/\~/\\textasciitilde{}/g;
    $term =~ s/\^/\\textasciicircum{}/g;
    $term =~ s{/}{\\slash{}}g;
    $term =~ s/([#\%\&\$_])/\\$1/g;
    $term;
}

sub generate_title {
    my $escapedlang = shift;
    my $vlaste_languages;
    if ($escapedlang eq "lojban") {
        $vlaste_languages = "la .lojban.";
    }
    else {
        $vlaste_languages = "la .lojban. jo'u la'o zoi $escapedlang zoi";
    }
    "lo vlaste be fu $vlaste_languages";
}

sub generate_chapters {
    my ($dbh, $lang, $escapedlang) = @_;
    my $langid = $dbh->selectrow_array("select langid from languages where tag=?", undef, $lang);
    ($escapedlang eq "lojban") ?
        generate_lojban_chapter($dbh, $langid, $lang, "lo smuni be bau la .lojban.") :
        generate_lojban_and_natural_chapters($dbh, $langid, $lang, $escapedlang);
}

sub generate_lojban_chapter {
    my ($dbh, $langid, $lang, $title) = @_;
    my $entries = generate_lojban_entries($dbh, $langid, $lang);
    qq(\\chapter{$title}) . $entries;
}

sub generate_lojban_entries {
    my ($dbh, $langid, $lang) = @_;
    my $entries = '';
    my $valsirows = fetch_sorted_valsi($dbh, $langid);
    foreach my $valsirow (@$valsirows) {
        my $entry = format_lojban_entry($valsirow, $lang);
        $entries .= $entry;
    }
    $entries;
}

sub fetch_sorted_valsi {
  my ($dbh, $langid) = @_;

  my $valsiquery = $dbh->prepare("
      select v.word, vbg.definitionid, c.rafsi, c.selmaho, c.definition, c.notes, t.descriptor
      from valsibestguesses vbg
      join valsi v
        on v.valsiid = vbg.valsiid
      join convenientdefinitions c
        on c.definitionid = vbg.definitionid
      join valsitypes t
        on t.typeid = v.typeid
      where vbg.langid=$langid");
  $valsiquery->execute;
  my $valsirows = $valsiquery->fetchall_arrayref({}); # fetch as hashrefs
  foreach my $valsirow (@$valsirows) {
    utf8::decode($valsirow->{'definition'});
    utf8::decode($valsirow->{'notes'});
  }

  # database collation handles apostrophes badly
  my @sorted_valsi = sort dictcollate @$valsirows;
  \@sorted_valsi;
}

sub dictcollate {
  lc($a->{'word'}) cmp lc($b->{'word'});
}

sub format_lojban_entry {
    my ($valsirow, $lang) = @_;
    my $entry = format_lojban_heading($valsirow->{'word'}, $valsirow->{'descriptor'});
    $entry   .= format_rafsi($valsirow->{'rafsi'});
    $entry   .= format_selmaho($valsirow->{'selmaho'});
    $entry   .= format_definition($valsirow->{'definition'}, $lang);
    $entry   .= format_notes($valsirow->{'notes'});
    $entry;
}

sub format_lojban_heading {
    my ($word, $valsitype) = @_;

    my $heading;
    my $escapedword = escapeall($word);
    if ($valsitype =~ /^(experimental|obsolete)/) {
        $heading = format_lojban_experimental_heading($escapedword);
    }
    else {
        $heading = format_normal_heading($escapedword);
    }
    $heading .= markboth($escapedword);
    $heading;
}

sub format_normal_heading {
    my $escapedword = shift;
    "\n\n{\\sffamily\\bfseries $escapedword}";
}

sub format_lojban_experimental_heading {
    my $escapedword = shift;
    my $unofficialwarning = '$\\triangle$ ';
    "\n\n{\\sffamily\\bfseries ${unofficialwarning}${escapedword}}";
}

# \markboth is for the top-of-page markings.
sub markboth {
    my $escapedword = shift;
    "\\markboth{". $escapedword . "}{" . $escapedword . "}";
}

sub format_rafsi {
    my $rafsi = shift;
    my $escaped_rafsi = escapeall($rafsi);
    $escaped_rafsi = compact($escaped_rafsi);
    $escaped_rafsi ? "\\enspace {\\ttfamily\\bfseries[$rafsi]} " : "";
}

sub compact {
    my $text = shift;
    $text =~ s/\s+$//;
    $text =~ s/^\s+//;
    $text =~ s/\s+/ / ;
    $text;
}

sub format_selmaho {
    my $selmaho = shift;
    $selmaho ?
        ("\\enspace {\\sffamily\\bfseries[". escapeall($selmaho) ."]} ") :
        "";
}

sub format_definition {
    my ($definition, $lang) = @_;
    my $carets_are_literal = ($lang eq $GUASPI);
    " " . escapetex($definition, $carets_are_literal);
}

# allow $ _ {} and sometimes ^ (used in tex definitions / notes)
sub escapetex {
    my ($term, $escape_carets) = @_;

    $term =~ s/>/\\textgreater{}/g;
    $term =~ s/</\\textless{}/g;

    $term =~ s/–/\\textendash{}/g;
    $term =~ s/—/\\textemdash{}/g;

    $term =~ s/\\/\\textbackslash{}/g;

    $term =~ s/\~/\\textasciitilde{}/g;

    if ($escape_carets) {
        $term =~ s/\^/\\textasciicircum{}/g;
    }

    $term =~ s{/}{\\slash{}}g;

    $term =~ s/([#\%\&])/\\$1/g;

    $term;
}

sub format_notes {
    my $notes = shift;
    my $formatted = "";
    if ($notes && snifftex($notes)) {
        $formatted = " \\textemdash{} " . escapetex($notes); # carets == TeX
    }
    elsif ($notes) {
        $formatted = " \\textemdash{} " . escapeall($notes);
    }
    $formatted;
}

sub snifftex {
  my $text = shift;
  !! ($text =~ /\$/);
}

sub generate_lojban_and_natural_chapters {
    my ($dbh, $langid, $lang, $escapedlang) = @_;

    my $vlaste_from_jbo  = "fanva fi la'o zoi $escapedlang zoi";
    my $lojban_chapter   = generate_lojban_chapter($dbh, $langid, $lang, $vlaste_from_jbo);

    my $vlaste_to_jbo   = "fanva fo la'o zoi $escapedlang zoi";
    my $natural_chapter = generate_natural_chapter($dbh, $langid);

    $lojban_chapter .
        "\n".
        qq(\\chapter{$vlaste_to_jbo}).
        $natural_chapter;
}

sub generate_natural_chapter {
    my ($dbh, $langid) = @_;
    my $entries = '';
    my $nlquery = execute_natural_query($dbh, $langid);
    while(defined(my $nlwbgrow = $nlquery->fetchrow_hashref())) {
        utf8::decode($nlwbgrow->{'word'});
        utf8::decode($nlwbgrow->{'meaning'});
        my $entry = format_natural_entry($nlwbgrow);
        $entries .= $entry;
    }
    $entries;
}

sub execute_natural_query {
    my ($dbh, $langid) = @_;
    my $nlquery = $dbh->prepare("
      select nlw.word, nlw.meaning, v.word as valsi, nlwbg.place
      from valsibestguesses vbg
      join valsi v
        on v.valsiid = vbg.valsiid
      join natlangwordbestguesses nlwbg
        on nlwbg.definitionid = vbg.definitionid
      join natlangwords nlw
        on nlw.wordid = nlwbg.natlangwordid
      where vbg.langid=$langid
      order by nlw.word
      ");
    $nlquery->execute();
    $nlquery;
}

sub format_natural_entry {
    my $nlwbgrow = shift;
    my $entry = format_natural_heading($nlwbgrow->{'word'});
    $entry   .= format_meaning($nlwbgrow->{'meaning'});
    $entry   .= format_valsi($nlwbgrow->{'valsi'});
    $entry   .= format_place($nlwbgrow->{'place'});
    $entry;
}

sub format_natural_heading {
  my $word = shift;
  my $escapedword = escapeall($word);
  my $heading = format_normal_heading($escapedword);
  $heading .= markboth($escapedword);
  $heading;
}

sub format_meaning {
    my $meaning = shift;
    $meaning ?
        ( "\\textit{(" . escapeall($meaning) . ")} " ) :
        "";
}

sub format_valsi {
    my $valsi = shift;
    " " . escapeall($valsi);
}

sub format_place {
    my $place = shift;
    ($place > 0) ? ( '$_{' . $place . '}$' ) : '';
}

sub latex_header {
  my ($title, $lang) = @_;
  my @d = localtime();
  my $jbo_date = "de'i li " . (1900 + $d[5]) . " pi'e " . (1 + $d[4]) . " pi'e " . $d[3];
  latex_preamble($lang) .
      q(
\title{). $title . q(}
\author{lo jboce'u}
\date{). $jbo_date . q(}

\begin{document}

\maketitle
)
}

sub latex_preamble {
  my $lang = shift;
  latex_preamble_intro() .
    latex_preamble_fonts($lang) .
    latex_preamble_outro();
}

sub latex_preamble_intro {
  q(
%!TEX encoding = UTF-8 Unicode
%!TEX TS-program = xelatex
\documentclass[notitlepage,twocolumn,a4paper,10pt]{book}
\renewcommand\chaptername{ni'o ni'o}

\usepackage{underscore}

\usepackage{fancyhdr} % important, lets us actually pull this stuff off.
\pagestyle{fancy}     % turns on the magic provided by fancyhdr

% Packages from http://linuxlibertine.sourceforge.net/Libertine-XeTex-EN.pdf
\usepackage{xunicode} % for XeTeX!
\usepackage{fontspec} % for XeTeX!
\usepackage{xltxtra} % for XeTeX!

% Font definitions mostly from http://linuxlibertine.sourceforge.net/Libertine-XeTex-EN.pdf
\defaultfontfeatures{Scale=MatchLowercase}% to adjust all used fonts to the same x-height
)
}

sub latex_preamble_fonts {
  my $lang = shift;
  latex_preamble_roman_fonts() .
    latex_preamble_cjk_fonts($lang);
}

sub latex_preamble_roman_fonts {
  q(
\setromanfont[Mapping=tex-text]{Linux Libertine O}
\setsansfont[Mapping=tex-text]{Linux Biolinum O}
)
}

sub latex_preamble_cjk_fonts {
  my $lang = shift;
  if ($lang eq $JAPANESE) {
  q(
\usepackage{xeCJK}
\setCJKmainfont{IPAexMincho}
\setCJKsansfont{IPAexGothic}
\setCJKmonofont{IPAGothic}
)
  }
  else {
  q(
\usepackage{xeCJK}
\setCJKmainfont[Mapping=tex-text]{Code2000}
)
  }
}

sub latex_preamble_outro {
  q(
\fancyhead{}          % empty out the header
\fancyfoot{}          % empty out the footer
\fancyhead[LE,LO]{\rightmark} % left side, odd and even pages
\fancyhead[RE,RO]{\leftmark}  % right side, odd and even pages
\fancyfoot[LE,RO]{\thepage}   % left side even, right side odd

\setlength{\parindent}{1 em}
)
}

sub latex_footer {
  q(
\end{document})
}

1;
