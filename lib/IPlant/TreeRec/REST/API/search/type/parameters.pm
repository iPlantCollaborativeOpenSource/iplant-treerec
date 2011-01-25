package IPlant::TreeRec::REST::API::search::type::parameters;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Apache2::Const -compile => qw(HTTP_OK);
use Class::Std::Utils;
use IPlant::TreeRec::REST::Handler;
use IPlant::TreeRec::REST::Initializer qw(get_tree_rec);
use List::MoreUtils;
use Readonly;

# The search subroutines fo each of the search types.
Readonly my %SEARCHER_FOR => (
    'go-search'           => sub { $_[0]->go_search( $_[1] ) },
    'go-accession-search' => sub { $_[0]->go_accession_search( $_[1] ) },
    'gene-id-search'      => sub { $_[0]->gene_id_search( $_[1] ) },
);

use base 'IPlant::TreeRec::REST::Handler';

{
    my %type_of;
    my %parameters_of;

    ##########################################################################
    # Usage      : $handler = IPlant::TreeRec::REST::API::search::type
    #                  ::parameters->new( $type, $parameters );
    #
    # Purpose    : Creates a new handler.
    #
    # Returns    : The new handler.
    #
    # Parameters : $type       - the search type.
    #              $parameters - the search parameters.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $type, $parameters ) = @_;

        # Create the new object.
        my $self = $class->SUPER::new();

        # Set the object properties.
        $type_of{ ident $self }       = $type;
        $parameters_of{ ident $self } = $parameters;

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
        delete $parameters_of{ ident $self };

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

        # Extract the search type and parameters.
        my $search_type = $type_of{ ident $self };
        my $parameters  = $parameters_of{ ident $self };

        # Get the subroutine for the search.
        my $search_sub_ref = $SEARCHER_FOR{$search_type};
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $search_sub_ref;

        # Perform the search.
        $response->data()->{'item'}
            = $search_sub_ref->( $treerec, $parameters );

        return Apache2::Const::HTTP_OK;
    }

    ##########################################################################
    # Usage      : $handler->isAuth( $method, $request );
    #
    # Purpose    : Determines whether or not a request is authorized.
    #              Authorization is curently handled at the level above this,
    #              so this method always returns a true value.
    #
    # Returns    : True if the request is authorized.
    #
    # Parameters : $method  - the HTTP methods (e.g. GET or POST).
    #              $request - the request.
    #
    # Throws     : No exceptions.
    sub isAuth {
        return 1;
    }
}

1;
__END__
