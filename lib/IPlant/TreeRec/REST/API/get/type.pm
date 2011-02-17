package IPlant::TreeRec::REST::API::get::type;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Class::Std::Utils;
use English qw(-no_match_vars);
use Exception::Class;
use IPlant::TreeRec::REST::Handler;
use IPlant::TreeRec::REST::API::get::type::qualifier;
use IPlant::TreeRec::REST::Initializer qw(get_tree_rec);
use List::MoreUtils qw(any);
use Readonly;

# The argument preprocessing subroutines for the various object types.
Readonly my %PREPROCESSOR_FOR => (
    'related-nodes' => \&_preprocess_reconciliation_args,
    'species-tree'  => \&_encode_species_tree_args,
    'species-data'  => \&_encode_species_tree_args,
);

# The supported HTTP methods for the various object types.
Readonly my %SUPPORTED_METHODS_FOR => (
    'related-nodes' => [qw( POST )],
    'species-tree'  => [qw( GET POST )],
    'species-data'  => [qw( GET POST )],
    'gene-tree'     => [qw( GET POST )],
    'gene-data'     => [qw( GET POST )],
);

# The name of the default species tree.
Readonly my $SPECIES_TREE => 'bowers_rosids';

# The getter subroutines for the various object types.
Readonly my %GETTER_FOR => (
    'related-nodes' => sub { $_[0]->resolve_reconciliations( $_[2] ) },
    'species-tree'  => sub { $_[0]->get_species_tree_file( $_[2] ) },
    'species-data'  => sub { $_[0]->get_species_tree_data( $_[2] ) },
    'gene-tree'     => sub { $_[0]->get_gene_tree_file( $_[2] ) },
    'gene-data'     => sub { $_[0]->get_gene_tree_data( $_[2] ) },
    'go-cloud'      => sub { $_[0]->get_go_cloud( $_[2] ) },
    'default'       => sub { $_[0]->get_file( $_[1], "" ) },
);

use base 'IPlant::TreeRec::REST::Handler';

{
    my %type_of;

    ##########################################################################
    # Usage      : $handler
    #                  = IPlant::TreeRec::REST::API::get::type->new($type);
    #
    # Purpose    : Creates a new handler.
    #
    # Returns    : The new handler.
    #
    # Parameters : $type - the search type.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $type ) = @_;

        # Create the new object.
        my $self = $class->SUPER::new();

        # Set the object properties.
        $type_of{ ident $self } = $type;

        return $self;
    }

    ##########################################################################
    # Usage      : N/A
    #
    # Purpose    : Cleans up after an instance of this class has gone out of
    #              scope.
    #
    # Returns    : Nothing.
    #
    # Parameters : None.
    #
    # Throws     : No exceptions.
    sub DESTROY {
        my ($self) = @_;

        # Clean up.
        delete $type_of{ ident $self };

        return;
    }

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

        # The results should be in JSON format.
        $request->requestedFormat('json');

        # Get the tree reconciliation object.
        my $treerec = get_tree_rec($request);

        # Extract the object type.
        my $object_type = $type_of{ ident $self };

        # Preprocess the argument if we're supposed to.
        my $arg;
        my $preprocessor_ref = $PREPROCESSOR_FOR{$object_type};
        if ( defined $preprocessor_ref ) {
            $arg = $preprocessor_ref->();
        }

        # Get the subroutine for object retrieval.
        my $getter_ref = $GETTER_FOR{$object_type}
            || $GETTER_FOR{default};

        # Retrieve the object.
        my $object = $getter_ref->( $treerec, $object_type, $arg );

        # Set the output according to the object.
        if ( $self->_object_is_file($object) ) {
            $self->_create_file_response( $request, $response, $object );
        }
        else {
            $self->_create_json_response( $request, $response, $object );
        }

        return Apache2::Const::HTTP_OK;
    }

    ##########################################################################
    # Usage      : $handler->POST( $request, $response );
    #
    # Purpose    : Handles a POST request.
    #
    # Returns    : An HTTP OK staus code.
    #
    # Parameters : $request  - the request.
    #              $response - the response.
    #
    # Throws     : No exceptions.
    sub POST {
        my ( $self, $request, $response ) = @_;

        # The results should be in JSON format.
        $request->requestedFormat('json');

        # Get the tree reconciliation object.
        my $treerec = get_tree_rec($request);

        # Extract the object type.
        my $object_type = $type_of{ ident $self };

        # Extract the parameters.
        my $r              = Apache2::RequestUtil->request();
        my $content_length = $r->headers_in()->{'Content-Length'};
        my $parameters;
        $r->read( $parameters, $content_length );

        # Preprocess the parameters if we're supposed to.
        my $preprocessor_ref = $PREPROCESSOR_FOR{$object_type};
        if ( defined $preprocessor_ref ) {
            $parameters = $preprocessor_ref->($parameters);
        }

        # Get the subroutine for object retrieval.
        my $getter_ref = $GETTER_FOR{$object_type}
            || $GETTER_FOR{default};

        # Retrieve the object.
        my $object = $getter_ref->( $treerec, $object_type, $parameters );

        # Set the output according to the object.
        if ( $self->_object_is_file($object) ) {
            $self->_create_file_response( $request, $response, $object );
        }
        else {
            $self->_create_json_response( $request, $response, $object );
        }

        return Apache2::Const::HTTP_OK;
    }

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

        # Get the list of supported methods.
        my $type = $type_of{ ident $self };
        my $supported_methods_ref = $SUPPORTED_METHODS_FOR{$type} || [];

        # Determine if the method that was used is supported.
        return any { $method eq $_ } @{$supported_methods_ref};
    }

    ##########################################################################
    # Usage      : $is_file
    #                  = $handler->_object_is_file($object);
    #
    # Purpose    : Determines whether or not the given object appears to be
    #              a file returned by our file retriever.
    #
    # Returns    : True if the object appears to be a file.
    #
    # Parameters : $object - the object to check.
    #
    # Throws     : No exceptions.
    sub _object_is_file {
        my ( $self, $object ) = @_;
        return ref $object eq 'HASH' && exists $object->{filename} ? 1 : 0;
    }

    ##########################################################################
    # Usage      : $handler->_create_file_response( $request, $response,
    #                  $object );
    #
    # Purpose    : Creates the appropriate response for a file object.
    #
    # Returns    : Nothing.
    #
    # Parameters : $request  - the request.
    #              $respones - the response object.
    #              $object   - the object being returned.
    #
    # Throws     : No exceptions.
    sub _create_file_response {
        my ( $self, $request, $response, $object ) = @_;

        # Set up the response object.
        $request->requestedFormat('bin');
        $response->bin( $object->{contents} );
        $response->binMimeType( $object->{content_type} );

        return;
    }

    ##########################################################################
    # Usage      : $handler->_create_json_response( $request, $response,
    #                  $object );
    #
    # Purpose    : Creates the appropriate response for a JSON object.
    #
    # Returns    : Nothing.
    #
    # Parameters : $request  - the request.
    #              $respones - the response object.
    #              $object   - the object being returned.
    #
    # Throws     : No exceptions.
    sub _create_json_response {
        my ( $self, $request, $response, $object ) = @_;

        # Set up the response object.
        $request->requestedFormat('json');
        $response->data()->{item} = $object;

        return;
    }

    ##########################################################################
    # Usage      : $handler->buildNext( $qualifier, $request );
    #
    # Purpose    : Builds the next handler in the chain.
    #
    # Returns    : The handler.
    #
    # Parameters : $qualifier - used to specify the desired object.
    #              $request   - the request object.
    #
    # Throws     : No exceptions.
    sub buildNext {
        my ( $self, $qualifier, $request ) = @_;

        # Get the search type.
        my $type = $type_of{ ident $self };

        # Determine the package of the next handler in the chain.
        my $current_package = ref $self;
        my $next_package    = "${current_package}::qualifier";

        # Instantiate and return the next handler.
        return $next_package->new( $type, $qualifier );
    }
}

##########################################################################
# Usage      : $json = _encode_species_tree_args($json);
#
# Purpose    : Encodes the JSON required by the subroutines used to fetch
#              species tree information from the database.
#
# Returns    : The JSON string.
#
# Parameters : $json - the arguments provided in the message body.
#
# Throws     : No exceptions.
sub _encode_species_tree_args {
    my ($json) = @_;
    my $result
        = defined $json
        ? $json
        : JSON->new()->encode( { 'speciesTreeName' => $SPECIES_TREE, } );
    return $result;
}

##########################################################################
# Usage      : $json = _preprocess_reconciliation_args($json);
#
# Purpose    : Preprocesses the arguments for reconciliation resolution.
#
# Returns    : The updated JSON string.
#
# Parameters : $json - the arguments provided in the message body.
#
# Throws     : No exceptions.
sub _preprocess_reconciliation_args {
    my ($orig) = @_;
    my $json = JSON->new();
    my $args_ref = $json->decode($orig);
    if ( !defined $args_ref->{speciesTreeName} ) {
        $args_ref->{speciesTreeName} = $SPECIES_TREE;
    }
    return $json->encode($args_ref);
}

1;
__END__
