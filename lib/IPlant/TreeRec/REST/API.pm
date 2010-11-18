package IPlant::TreeRec::REST::API;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use IPlant::TreeRec::REST::Handler;
use List::MoreUtils;

use base 'IPlant::TreeRec::REST::Handler';

##########################################################################
# Usage      : $handler->isAuth( $method, $request );
#
# Purpose    : Determines whether or not a request is authorized.  This
#              handler supports GET and POST requests.
#
# Returns    : True if the request is authorized.
#
# Parameters : $method  - the HTTP methods (e.g. GET or POST).
#              $request - the request.
#
# Throws     : No exceptions.
sub isAuth {
    my ( $self, $method, $request ) = @_;
    return any { $method eq $_ } qw( GET POST );
}

1;
__END__
