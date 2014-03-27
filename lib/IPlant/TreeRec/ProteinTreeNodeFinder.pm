package IPlant::TreeRec::ProteinTreeNodeFinder;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );
use Memoize;
use Readonly;

{
    my %dbh_of;

    ##########################################################################
    # Usage      : $finder
    #                  = IPlant::TreeRec::ProteinTreeNodeFinder->new($dbh);
    #
    # Purpose    : Creates a new protein tree node finder.
    #
    # Returns    : The new finder.
    #
    # Parameters : $dbh - the database handle.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $dbh ) = @_;

        # Create the new object.
        my $self = bless anon_scalar, $class;

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
    # Usage      : @node_ids = $finder->for_species($family_name,
    #                  $species_tree_node_id);
    #
    # Purpose    : Gets the list of matching protein tree node IDs for a
    #              species tree node ID.
    #
    # Returns    : The list of protein tree node IDs.
    #
    # Parameters : $family_name          - the name of the gene family.
    #              $species_tree_node_id - the species tree node identifier.
    #
    # Throws     : IPlant::TreeRec::NodeNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub for_species {
        my ( $self, $family_name, $species_tree_node_id ) = @_;

        # Fetch the databse handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the objects we need for the query.
        my $protein_tree
            = $dbh->resultset('ProteinTree')->for_family_name($family_name);
        my $species_tree_node = $dbh->resultset('SpeciesTreeNode')
            ->for_id($species_tree_node_id);

        # Perform the query.
        my @nodes = $dbh->resultset('ProteinTreeNode')->search(
            {   'protein_tree_id'  => $protein_tree->id(),
                'cvterm.name'      => 'S',
                'attributes.value' => $species_tree_node->label(),
            },
            { join => { 'attributes' => 'cvterm' } },
        );

        return map { $_->id() } @nodes;
    }
}

1;
__END__
