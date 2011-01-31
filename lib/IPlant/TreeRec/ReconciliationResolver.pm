package IPlant::TreeRec::ReconciliationResolver;

use 5.008000;

use warnings;
use strict;

our $VERSION = '0.0.1';

use Carp;
use Class::Std::Utils;
use IPlant::TreeRec::X;
use JSON;

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
    # Usage      : $results_ref = $resolver->resolve(
    #                  {   'speciesTreeName' => $species_tree_name,
    #                      'familyName'      => $family_name,
    #                      'speciesTreeNode' => $species_tree_node_id,
    #                      'geneTreeNode'    => $gene_tree_node_id,
    #                      'edgeSelected'    => $leading_edge_selected,
    #                  }
    #              );
    #
    # Purpose    : Resolves a partial reconciliation.  The reconciliation
    #              information passed to this subroutine must contain three or
    #              four pieces of information.  The species tree name and the
    #              gene family name are always required.  If the gene tree
    #              node ID is also provided then the corresponding species
    #              tree node ID and a flag indicating whether the edge leading
    #              to the species tree node is selected are filled in.  If the
    #              species tree node ID and edge-selected flag are provided
    #              then the gene tree node ID will be filled in.  The result
    #              of this subroutine is reference to a list of filled-in
    #              reconciliation records.
    #
    # Returns    : A reference to a list of filled in reconciliation records.
    #
    # Parameters : speciesTreeName - the name of the species tree.
    #              familyName      - the gene family name.
    #              speciesTreeNode - the species tree node identifier.
    #              geneTreeNode    - the gene tree node identifier.
    #              edgeSelected    - true if a species tree edge is selected.
    #
    # Throws     : IPlant::TreeRec::IllegalArgumentException
    #              IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::ReconciliationNotFoundException
    sub resolve {
        my ( $self, $args_ref ) = @_;

        # Extract the arguments.
        my $species_tree_name = $args_ref->{speciesTreeName};
        my $family_name       = $args_ref->{familyName};
        my $species_node_id   = $args_ref->{speciesTreeNode};
        my $gene_node_id      = $args_ref->{geneTreeNode};
        my $edge_selected     = $args_ref->{edgeSelected};

        # Validate the arguments.
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $species_tree_name || !defined $family_name;
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $species_node_id && !defined $gene_node_id;
        IPlant::TreeRec::IllegalArgumentException->throw()
            if defined $species_node_id && defined $gene_node_id;
        IPlant::TreeRec::IllegalArgumentException->throw()
            if defined $species_node_id && !defined $edge_selected;

        # Fetch the reconciliation.
        my $reconciliation
            = $self->_get_reconciliation( $species_tree_name, $family_name );

        # Resolve the node.
        my $results_ref
            = defined $species_node_id
            ? $self->_resolve_species_node( $reconciliation, $args_ref )
            : $self->_resolve_gene_node( $reconciliation, $args_ref );

        return $results_ref;
    }

    ##########################################################################
    # Usage      : $results_ref = $resolver->_resolve_species_node(
    #                  $reconciliation, $search_params_ref );
    #
    # Purpose    : Finds nodes in the gene tree that are related to the
    #              specified species node or edge.
    #
    # Returns    : The search results.
    #
    # Parameters : $reconciliation    - the reconciliation record.
    #              $search_params_ref - the orgiginal search parameters.
    #
    # Throws     : No exceptions.
    sub _resolve_species_node {
        my ( $self, $reconciliation, $search_params_ref ) = @_;

        # Extract the search parameters.
        my $species_node_id = $search_params_ref->{speciesTreeNode};
        my $edge_selected   = $search_params_ref->{edgeSelected};

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Look up the matching reconciliation nodes.
        my @nodes = $dbh->resultset('ReconciliationNode')->search(
            {   'reconciliation_id'  => $reconciliation->id(),
                'host_child_node_id' => $species_node_id,
                'is_on_node'         => !$edge_selected,
            }
        );

        return $self->_format_results( $search_params_ref, @nodes );
    }

    ##########################################################################
    # Usage      : $results_ref = $resolver->_resolve_species_node(
    #                  $reconciliation, $search_params_ref );
    #
    # Purpose    : Finds nodes or edges in the species tree that are related
    #              to the specified gene node.
    #
    # Returns    : The search results.
    #
    # Parameters : $reconciliation    - the reconciliation record.
    #              $search_params_ref - the original search parameters.
    #
    # Throws     : No exceptions.
    sub _resolve_gene_node {
        my ( $self, $reconciliation, $search_params_ref ) = @_;

        # Extract the search parameters.
        my $gene_node_id = $search_params_ref->{geneTreeNode};

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Look up the matching reconciliation nodes.
        my @nodes = $dbh->resultset('ReconciliationNode')
            ->search( { 'reconciliation_id' => $reconciliation->id(), 'node_id' => $gene_node_id, } );

        return $self->_format_results( $search_params_ref, @nodes );
    }

    ##########################################################################
    # Usage      : $results_ref = $resolver->_format_results(
    #                  $search_params_ref, @nodes );
    #
    # Purpose    : Formats the results of a resolution.
    #
    # Returns    : The results as a reference to an array of hashes.  Each
    #              hash is in the same format as the search parameters that
    #              were passed to $resolver->resolve().
    #
    # Parameters : $search_params_ref - a reference to the search parameters.
    #              @nodes             - a list of reconciliation nodes.
    #
    # Throws     : No exceptions.
    sub _format_results {
        my ( $self, $search_params_ref, @nodes ) = @_;

        # Extract the search parameters we need.
        my $species_tree_name = $search_params_ref->{speciesTreeName};
        my $family_name       = $search_params_ref->{familyName};

        # Format the results.
        my @results;
        for my $node (@nodes) {
            my $edge_selected
                = $node->is_on_node() ? JSON::false : JSON::true;
            my $result_ref = {
                'speciesTreeName' => $species_tree_name,
                'familyName'      => $family_name,
                'speciesTreeNode' => $node->host_child_node_id(),
                'geneTreeNode'    => $node->node_id(),
                'edgeSelected'    => $edge_selected,
            };
            push @results, $result_ref;
        }

        return \@results;
    }

    ##########################################################################
    # Usage      : $reconciliation = $resolver->_get_reconciliation(
    #                  $species_tree_name, $family_name );
    #
    # Purpose    : Retrieves a reconciliation from the database.
    #
    # Returns    : The reconciliation.
    #
    # Parameters : $species_tree_name - the name of the species tree.
    #              $family_name       - the name of the gene family.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::ReconciliationNotFoundException
    sub _get_reconciliation {
        my ( $self, $species_tree_name, $family_name ) = @_;

        # Get the species tree and protein tree.
        my $species_tree = $self->_get_species_tree($species_tree_name);
        my $protein_tree = $self->_get_protein_tree($family_name);

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the reconciliation.
        my $reconciliation = $dbh->resultset('Reconciliation')->find(
            {   'species_tree_id' => $species_tree->id(),
                'protein_tree_id' => $protein_tree->id(),
            }
        );
        IPlant::TreeRec::ReconciliationNotFoundException->throw()
            if !defined $reconciliation;

        return $reconciliation;
    }

    ##########################################################################
    # Usage      : $reconciliation = $resolver->_get_species_tree(
    #                  $species_tree_name );
    #
    # Purpose    : Retrieves a species tree from the database.
    #
    # Returns    : $species_tree_name - the name of the species tree.
    #
    # Parameters : $species_tree_name - the name of the species tree.
    #
    # Throws     : IPlant::TreeRec::TreeNotFoundException
    sub _get_species_tree {
        my ( $self, $species_tree_name ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the species tree.
        my $species_tree = $dbh->resultset('SpeciesTree')
            ->find( { 'species_tree_name' => $species_tree_name } );
        IPlant::TreeRec::TreeNotFoundException->throw()
            if !defined $species_tree;

        return $species_tree;
    }

    ##########################################################################
    # Usage      : $tree = $resolver->_get_protein_tree($family_name);
    #
    # Purpose    : Retrieves the protein tree for the given gene family name
    #              from the database.
    #
    # Returns    : The protein tree.
    #
    # Parameters : $family_name - the name of the gene family.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub _get_protein_tree {
        my ( $self, $family_name ) = @_;

        # Get the gene family.
        my $dbh    = $dbh_of{ ident $self };
        my $family = $dbh->resultset('Family')
            ->find( { 'stable_id' => $family_name } );
        IPlant::TreeRec::GeneFamilyNotFound->throw()
            if !defined $family;

        # Get the protein tree from the database.
        my $db_tree = $family->protein_tree();
        IPlant::TreeRec::TreeNotFoundException->throw()
            if !defined $db_tree;

        return $db_tree;
    }
}

1;
__END__
