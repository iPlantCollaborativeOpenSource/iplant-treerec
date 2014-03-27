package IPlant::TreeRec::REST::API::download;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use IPlant::TreeRec::REST::Handler;
use IPlant::TreeRec::REST::API::download::type;

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
    return any { $method eq $_ } qw(GET);
}

##########################################################################
# Usage      : $handler->buildNext( $type, $request );
#
# Purpose    : Builds the next handler in the chain.
#
# Returns    : The handler.
#
# Parameters : $type    - the search type from the URL.
#              $request - the request object.
#
# Throws     : No exceptions.
sub buildNext {
    my ( $self, $type, $request ) = @_;

    # Determine the package of the next handler in the chain.                                                                                                                                                                                                                 
    my $current_package = ref $self;
    my $next_package    = "${current_package}::type";

    # Instantiate and return the next handler.                                                                                                                                                                                                                                
    return $next_package->new($type);
}

1;
__END__
