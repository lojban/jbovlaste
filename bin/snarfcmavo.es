#!/usr/bin/perl

use DBI;
use IPC::Open2;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";
use db;

my $time = time();

my $lang = 4; # Spanish

my $userid = 10;  # xorxes

open(GISMU,$ARGV[0]);
while(<GISMU>) {
    if(/^(.{11})(.{9})(.{42})(.{5,109})(.*)./)
    {
	my($cmavo,$selmaho,$glossword,$definition,$notes) = ($1,$2,$3,$4,$5);
	# Clean out spaces.
	$cmavo =~ s/\s+$//;
	$selmaho =~ s/\s+$//;
	$glossword =~ s/\s+$//;
	$definition =~ s/\s+$//;
	$notes =~ s/\s+$//;

	# Turn x1 into LaTex format $x_{1}$.  The HTML output engine
	# should turn that LaTeX pattern into nice HTML.
	$definition =~ s/x(\d)/\$x_{$1}\$/g;

	$notes = undef unless length($notes);

	$cmavo =~ s/^\.//g;
	$cmavo =~ s/^\s+//g;

	####
	# Protect ' in variables for lookup.
	####
	my $pcmavo = $cmavo;
	$pcmavo =~ s/\'/\'\'/g;

	next if $cmavo =~ /\d/;

	#print "GOING!\n";
	#print "$cmavo###$selmaho###$glossword###$definition###$notes\n";

        ####
        # Now we try to turn the notes into something that approximates
        # valid Wiki text.
        ####
	# Remaning []s.
	$notes =~ s/\[/\(/g;
	$notes =~ s/\]/\)/g;
	$definition =~ s/\[/\(/g;
	$definition =~ s/\]/\)/g;

	#####
	# Handle x1 things.
	#####
	$notes =~ s/x(\d)(\W)/\$x_$1\$$2/g;
	$notes =~ s/(\W)x(\d)/$1\$x_$2\$/g;

        # (foo, foo, foo, ...  )
        if( $notes =~ s/\((?:cf\.)?\s*([a-z', ]+)\)/Ver también ####./ )
        {
            $notespart = $1;

            # manci,
            $notespart =~ s/([a-z']+),/{$1}, /g;

            # manci
            $notespart =~ s/([a-z']+)\s*$/{$1}/g;

            $notes =~ s/####/$notespart/;
        }

        $notes =~ s/\s+$//;

	######
	# Unicode
	######
	my $pid = IPC::Open2::open2( RDRFH, WTRFH, '/usr/bin/recode', 'ISO-8859-1..UTF-8');
	print WTRFH $definition, "\n";
	close WTRFH;
	$definition = <RDRFH>;
	close RDRFH;
	waitpid $pid, 0;
	chomp $definition;

	$pid = IPC::Open2::open2( RDRFH, WTRFH, '/usr/bin/recode', 'ISO-8859-1..UTF-8');
	print WTRFH $notes, "\n";
	close WTRFH;
	$notes = <RDRFH>;
	close RDRFH;
	waitpid $pid, 0;
	chomp $notes;

	$pid = IPC::Open2::open2( RDRFH, WTRFH, '/usr/bin/recode', 'ISO-8859-1..UTF-8');
	print WTRFH $glossword, "\n";
	close WTRFH;
	$glossword = <RDRFH>;
	close RDRFH;
	waitpid $pid, 0;
	chomp $glossword;

        #print "!#!#! $notes\n\n";
	#print;
	#print "$cmavo###$selmaho###$glossword###$definition###$notes\n\n";
	print "$cmavo, ";

	####
	# Retrieve the basic valsi information (should already be in the
	# DB)
	####

	$valsiid = $dbh->selectrow_array("SELECT valsiid FROM valsi WHERE word='$pcmavo'\n");

	####
	# Delete old versions
	####

	my $definitionid = $dbh->selectrow_array("SELECT definitionid FROM definitions
	    WHERE valsiid=$valsiid AND userid=$userid AND langid=$lang");
	my $wordid = $dbh->selectrow_array("SELECT wordId FROM natlangwords
	    WHERE langid=$lang AND word=? AND userid=$userid", undef, $glossword);

	if( $definitionid )
	{
	    print "word: $cmavo, definitionid $definitionid.\n";
	    $dbh->begin_work;
	    ## print "\nValsi id $valsiid found, deletions beginning.\nPlease ignore any errors about referential integrity.\n\n";
	    $dbh->do("DELETE FROM keywordmapping WHERE definitionid=?", undef, $definitionid );
	    $dbh->do("DELETE FROM natlangwords WHERE word=? AND langid=?", undef, $glossword, $lang );
	    $dbh->do("DELETE FROM definitions WHERE langid=? AND definitionid=? AND userid=?", undef, $lang, $definitionid, $userid);
	    $dbh->commit;
	}

	## print "pcm: $pcmavo";
	## print("SELECT valsiid FROM valsi WHERE word='$pcmavo'\n");
	## print "VALSI: $valsiid\n";

	####
	# Enter the definition information.
	####
	$dbh->begin_work;

	$defnum = $dbh->selectrow_array("SELECT definitionnum 
	    FROM definitions WHERE valsiid=? AND langid=?",
	    undef, $valsiid, $lang );

	$dbh->do("INSERT INTO definitions (langid, valsiid, definitionNum, definition, notes, userid, time, selmaho) VALUES
	    (?, ?, ?, ?, ?, ?, ?, ?)",
	    undef, $lang, $valsiid, $defnum + 1, $definition, $notes, $userid, $time, $selmaho);
	
	# Retrieve the DefinitionID that got generated above.
	$defid = $dbh->selectrow_array("SELECT definitionid 
	    FROM definitions WHERE valsiid=? AND userid=? AND time=? AND langid=?",
	    undef, $valsiid, $userid, $time, $lang );

	$dbh->commit;

	####
	# Protect ' in variables for lookup.
	####
	my $pdefinition = $definition;
	$pdefinition =~ s/\'/\'\'/g;
	my $pnotes = $notes;
	$pnotes =~ s/\'/\'\'/g;
	## print "$pdefinition, $pnotes\n";

	## print("SELECT definitionId FROM definitions where langid=$lang
	##    AND valsiId=$valsiid AND definitionNum=1" );
	## print "DEFID: $defid\n";

	####
	# Enter the basic natlang word information for the gloss word.
	####
	$dbh->begin_work;
        $dbh->do("INSERT INTO natlangwords (langid, word, meaningNum, userid, time ) VALUES (?, ?, ?, ?, ?)",
                undef,
		$lang, $glossword, 1, $userid, $time );
	$dbh->commit;

	####
	# Retrieve the WordID that got generated above.
	####
	my $wordid = $dbh->selectrow_array("SELECT last_value FROM natlangwords_wordid_seq");
	## print("SELECT wordId FROM natlangwords where langid=$lang AND word=?\n", undef, $glossword);
	## print "WORDID: $wordid\n";
	## print "$valsiid, $defid, $wordid\n";

	####
	# Enter the mapping from the gloss word to the definition.
	####
	$dbh->begin_work;
        $dbh->do("INSERT INTO keywordmapping (definitionId, natlangwordId, place ) VALUES
		(
		?,
		?,
		0
		)",
                undef,
		$defid, $wordid );
	$dbh->commit;

    }
}

$dbh->disconnect;

print "NOTE!  rafsi for cmavo have *not* been entered.  Or, if they
have, they will be overridden by future runs of snarfcmavo.

To fix this, run snarfrafsi gismu.txt.

";
