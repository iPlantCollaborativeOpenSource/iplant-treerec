package IPlant::TreeRec::REST::API::get::type::qualifier;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Class::Std::Utils;
use IPlant::TreeRec::REST::Handler;
use IPlant::TreeRec::REST::Initializer qw(get_tree_rec);
use JSON;
use Readonly;

# The default species tree name.
Readonly my $SPECIES_TREE => 'bowers_rosids';

# The argument preprocessing subroutines for the various object types.
Readonly my %PREPROCESSOR_FOR => (
    'species-tree' => \&_encode_tree_args,
    'species-data' => \&_encode_tree_args,
    'gene-tree'    => \&_encode_tree_args,
    'gene-data'    => \&_encode_tree_args,
);

# The getter subroutines for the various object types.
Readonly my %GETTER_FOR => (
    'gene-family-details' => sub { $_[0]->get_gene_family_details( $_[2] ) },
    'species-tree'        => sub { $_[0]->get_species_tree_file( $_[2] ) },
    'species-data'        => sub { $_[0]->get_species_tree_data( $_[2] ) },
    'gene-tree'           => sub { $_[0]->get_gene_tree_file( $_[2] ) },
    'gene-data'           => sub { $_[0]->get_gene_tree_data( $_[2] ) },
    'default'             => sub { $_[0]->get_file( $_[1], $_[2] ) },
);

use base 'IPlant::TreeRec::REST::Handler';

{
    my %type_of;
    my %qualifier_of;

    ##########################################################################
    # Usage      : $handler = IPlant::TreeRec::REST::API::get::type
    #                  ::qualifier->new( $type, $qualifier );
    #
    # Purpose    : Creates a new handler.
    #
    # Returns    : The new handler.
    #
    # Parameters : $type - the search type.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $type, $qualifier ) = @_;

        # Create the new object.
        my $self = $class->SUPER::new();

        # Set the object properties.
        $type_of{ ident $self }      = $type;
        $qualifier_of{ ident $self } = $qualifier;

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
        delete $qualifier_of{ ident $self };

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

        # Extract the object type and qualifier.
        my $object_type = $type_of{ ident $self };
        my $qualifier   = $qualifier_of{ ident $self };

        # Preprocess the qualifier if applicable.
        my $preprocessor_ref = $PREPROCESSOR_FOR{$object_type};
        if ( defined $preprocessor_ref ) {
            $qualifier = $preprocessor_ref->($qualifier);
        }

        # Get the subroutine for object retrieval.
        my $getter_ref = $GETTER_FOR{$object_type}
            || $GETTER_FOR{default};

        # Retrieve the object.
        my $object = $getter_ref->( $treerec, $object_type, $qualifier );

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
}

##########################################################################
# Usage      : $json = _encode_tree_args($family_name);
#
# Purpose    : Encodes the JSON required by the subroutines used to fetch
#              tree information from the database.
#
# Returns    : The JSON string.
#
# Parameters : $family_name - the gene family name.
#
# Throws     : No exceptions.
sub _encode_tree_args {
    my ($family_name) = @_;
    return JSON->new()->encode(
        {   'familyName'      => $family_name,
            'speciesTreeName' => $SPECIES_TREE,
        }
    );
}

1;
__END__
