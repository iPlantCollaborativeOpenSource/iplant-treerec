package IPlant::TreeRec::REST::Handler;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Apache2::Const -compile => qw( HTTP_OK HTTP_NOT_FOUND );
use Apache2::REST::Handler;

use base 'Apache2::REST::Handler';

##########################################################################
# Usage      : $handler->GET( $request, $response );
#
# Purpose    : Handles a GET request.
#
# Returns    : An HTTP OK staus code.
#
# Parameters : $request  - the request.
#              $response - the response.
#
# Throws     : No exceptions.
sub GET {
    my ( $self, $request, $response ) = @_;
    $request->requestedFormat('json');
    $response->data()->{'api_mess'} = "Welcome to TreeRec!";
    return Apache2::Const::HTTP_OK;
}

##########################################################################
# Usage      : $handler->POST( $request, $response );
#
# Purpose    : Handles a POST request.  This is the default POST handler
#              for handler classes that support the POST method.
#
# Returns    : An HTTP not found status code.
#
# Parameters : $request  - the request.
#              $response - the response.
#
# Throws     : No exceptions.
sub POST {
    my ( $self, $request, $response ) = @_;
    $request->requestedFormat('json');
    $response->data()->{'api_mess'} = "No POST service at this URI.";
    return Apache2::Const::HTTP_NOT_FOUND;
}

##########################################################################
# Usage      : $handler->isAuth( $method, $request );
#
# Purpose    : Determines whether or not a request is authorized.  By
#              default, all GET requests are authorized.
#
# Returns    : True if the request is authorized.
#
# Parameters : $method  - the HTTP methods (e.g. GET or POST).
#              $request - the request.
#
# Throws     : No exceptions.
sub isAuth {
    my ( $self, $method, $request ) = @_;
    return $method eq 'GET' ? 1 : 0;
}

1;
__END__
