package IPlant::TreeRec::ReconciliationLoader;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Carp;
use Class::Std::Utils;
use IPlant::TreeRec::X;
use Readonly;

{
    my %dbh_of;

    ##########################################################################
    # Usage      : $loader = IPlant::TreeRec::ReconciliationLoader->new($dbh);
    #
    # Purpose    : Creates a new reconciliation loader.
    #
    # Returns    : The new loader.
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
    # Usage      : $reconciliation_ref = $loader->load($reconciliation);
    #
    # Purpose    : Loads the information for the given reconciliation.
    #
    # Returns    : A reference to a data structure representing the
    #              reconciliation.
    #
    # Parameters : $reconciliation - the reconciliation to load.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub load {
        my ( $self, $reconciliation ) = @_;

        # Make sure that there's a reconciliation to load.
        return if !defined $reconciliation;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        return {
            speciesToGene => $self->_species_to_gene($reconciliation),
            geneToSpecies => $self->_gene_to_species($reconciliation),
        };
    }

    ##########################################################################
    # Usage      : $hash_ref = $loader->_species_to_gene($reconciliation);
    #
    # Purpose    : Produces a data structure that maps species tree nodes to
    #              gene tree nodes.
    #
    # Returns    : The node map.
    #
    # Parameters : $reconciliation - the reconciliation.
    #
    # Throws     : No exceptions.
    sub _species_to_gene {
        my ( $self, $reconciliation ) = @_;

        # Build the map elements.
        my @map_elements;
        for my $node ( $reconciliation->nodes() ) {
            next if !$self->_node_qualifies_for_map($node);
            my $source_element_type = $node->is_on_node() ? 'node' : 'edge';
            my $map_element = {
                'source_node_id'      => $node->host_child_node_id(),
                'source_element_type' => $source_element_type,
                'dest_node_id'        => $node->node_id(),
                'dest_element_type'   => 'node',
            };
            push @map_elements, $map_element;
        }

        return \@map_elements;
    }

    ##########################################################################
    # Usage      : $hash_ref = $loader->_gene_to_species($reconciliation);
    #
    # Purpose    : Produces a data structure that maps gene tree nodes to
    #              species tree nodes.
    #
    # Returns    : The node map.
    #
    # Parameters : $reconciliation - the reconciliation.
    #
    # Throws     : No exceptions.
    sub _gene_to_species {
        my ( $self, $reconciliation ) = @_;

        # Build the map elements.
        my @map_elements;
        for my $node ( $reconciliation->nodes() ) {
            next if !$self->_node_qualifies_for_map($node);
            my $event_type        = $self->_determine_event_type($node);
            my $dest_element_type = $node->is_on_node() ? 'node' : 'edge';
            my $map_element       = {
                'source_node_id'      => $node->node_id(),
                'source_element_type' => 'node',
                'dest_node_id'        => $node->host_child_node_id(),
                'dest_element_type'   => $dest_element_type,
                'event_type'          => $event_type,
            };
            push @map_elements, $map_element;
        }

        return \@map_elements;
    }

    ##########################################################################
    # Usage      : $qualifies = $loader->_node_qualifies_for_map($node);
    #
    # Purpose    : Determines whether or not the given reconciliation node
    #              qualifies for our maps.
    #
    # Returns    : True if the node qualifies for the maps.
    #
    # Parameters : $node - the reconciliation node to examine.
    #
    # Throws     : No exceptions.
    sub _node_qualifies_for_map {
        my ( $self, $node ) = @_;

        # Extract the information we need from the node.
        my $is_on_node = $node->is_on_node();
        my $parent_id  = $node->host_parent_node_id();
        my $child_id   = $node->host_child_node_id();

        # Determine if the node qualifies.
        my $node_qualifies
            = !defined $parent_id && !defined $child_id ? 0
            :                                             1;

        return $node_qualifies;
    }

    ##########################################################################
    # Usage      : $event_type = $loader->_determine_event_type($node);
    #
    # Purpose    : Determines the type of the event indicated by the given
    #              reconciliation node.
    #
    # Returns    : The event type.
    #
    # Parameters : $node - the reconciliation node to examine.
    #
    # Throws     : No exceptions.
    sub _determine_event_type {
        my ( $self, $node ) = @_;

        # Get the database handle,
        my $dbh = $dbh_of{ ident $self };

        # Determine if the protein tree node is a leaf node.
        my $child_count = $dbh->resultset('ProteinTreeNode')
            ->count( { 'parent_id' => $node->node_id() } );
        my $is_leaf = $child_count == 0;

        # Determine the event type.
        my $event_type
            = $is_leaf            ? 'leaf'
            : $node->is_on_node() ? 'speciation'
            :                       'duplication';

        return $event_type;
    }
}

1;
__END__
