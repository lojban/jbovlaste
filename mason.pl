#!/usr/bin/perl
#
# This is a basic, fairly fuctional Mason handler.pl.
#
# For something a little more involved, check out session_handler.pl

my $basedir="/srv/jbovlaste/current";

push @INC, "$basedir/lib";

package HTML::Mason;

# Bring in main Mason package.
use HTML::Mason;

# Bring in ApacheHandler, necessary for mod_perl integration.
# Uncomment the second line (and comment the first) to use
# Apache::Request instead of CGI.pm to parse arguments.
use HTML::Mason::ApacheHandler;
# use HTML::Mason::ApacheHandler (args_method=>'mod_perl');

# Uncomment the next line if you plan to use the Mason previewer.
#use HTML::Mason::Preview;

use strict;

# List of modules that you want to use from components (see Admin
# manual for details)
{
    package HTML::Mason::Commands;
    use DBI;
}

{
    package HTML::Mason::Component;
    my($dbh,%session);
}

# Create Mason objects
#
my $parser = new HTML::Mason::Parser;
my $interp = new HTML::Mason::Interp (parser=>$parser,
                                      comp_root=>"$basedir",
                                      data_dir=>"$basedir/mason");
my $ah = new HTML::Mason::ApacheHandler (interp=>$interp);

# Activate the following if running httpd as root (the normal case).
# Resets ownership of all files created by Mason at startup.
#
#chown (Apache->server->uid, Apache->server->gid, $interp->files_written);

sub handler
{
    my ($r) = shift;

    # If you plan to intermix images in the same directory as
    # components, activate the following to prevent Mason from
    # evaluating image files as components.
    #
    return -1 if $r->content_type && $r->content_type !~ m|^text/html|i
	&& $r->content_type !~ m|directory$|i;
    
    my $status = $ah->handle_request($r);

    return $status;
}

1;
