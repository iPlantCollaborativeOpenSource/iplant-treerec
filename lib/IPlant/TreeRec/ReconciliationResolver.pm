package IPlant::TreeRec::ReconciliationResolver;

use 5.008000;

use warnings;
use strict;

our $VERSION = '0.0.1';

use Carp;
use Class::Std::Utils;

{
    my %dbh_of;

    ##########################################################################
    # Usage      : $resolver
    #                  = IPlant::TreeRec::ReconciliationResolver->new($dbh);
    #
    # Purpose    : Initializes a new reconciliation resolver instance with the
    #              given datbase handle.
    #
    # Returns    : The new reconciliation resolver.
    #
    # Parameters : $dbh - the database handle.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $dbh ) = @_;

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Initialize the properties.
        $dbh_of{ ident $self } = $dbh;

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
        delete $dbh_of{ ident $self };

        return;
    }

    ##########################################################################
    # Usage      : $families_ref = $resolver->get_families_with_duplications(
    #                  $species_tree_name, $node_id, $leading_edge );
    #
    # Purpose    : Gets the identifiers for the gene families with duplication
    #              events at a specific location 
    # Returns    :
    # Parameters :
    # Throws     : No exceptions.
    # Comments   : None.
    # See Also   : N/A

}

1;
__END__
