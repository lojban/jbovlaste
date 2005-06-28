# MIME::Base64, except modified to use a pleasently URL-friendly set
# of characters. (no icky + or /)

package urlbase64;

use strict;
use vars qw(@ISA @EXPORT $VERSION $OLD_CODE);

require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(encode_base64 decode_base64);

use integer;

sub encode_base64 ($;$)
{
    my $res = "";
    my $eol = $_[1];
    $eol = "\n" unless defined $eol;
    pos($_[0]) = 0;                          # ensure start at the beginning

    $res = join '', map( pack('u',$_)=~ /^.(\S*)/, ($_[0]=~/(.{1,45})/gs));

    $res =~ tr|` -_|AA-Za-z0-9_\-|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'.' x $padding/e if $padding;
    # break encoded string into lines of no more than 76 characters each
    if (length $eol) {
	$res =~ s/(.{1,76})/$1$eol/g;
    }
    return $res;
}


sub decode_base64 ($)
{
    local($^W) = 0; # unpack("u",...) gives bogus warning in 5.00[123]

    my $str = shift;
    $str =~ tr|A-Za-z0-9_\.\-||cd;            # remove non-base64 chars
    if (length($str) % 4) {
	require Carp;
	Carp::carp("Length of base64 data not a multiple of 4")
    }
    $str =~ s/\.+$//;                        # remove padding
    $str =~ tr|A-Za-z0-9_\-| -_|;            # convert to uuencoded format

    return join'', map( unpack("u", chr(32 + length($_)*3/4) . $_),
	                $str =~ /(.{1,60})/gs);
}

# Set up aliases so that these functions also can be called as
#
#    MIME::Base64::encode();
#    MIME::Base64::decode();

*encode = \&encode_base64;
*decode = \&decode_base64;

1;
