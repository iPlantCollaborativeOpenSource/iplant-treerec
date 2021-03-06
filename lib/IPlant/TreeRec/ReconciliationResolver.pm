package IPlant::TreeRec::ReconciliationResolver;

use 5.008000;

use warnings;
use strict;

our $VERSION = '0.0.2';

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
    #              includeSubtree  - true if the subtree should be selected.
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

        # Fetch the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Fetch the reconciliation.
        my $reconciliation = $dbh->resultset('Reconciliation')
            ->for_species_tree_and_family( $species_tree_name, $family_name );

        # Resolve the node.
        my $results_ref
            = defined $species_node_id
            ? $self->_resolve_species_nodes( $reconciliation, $args_ref )
            : $self->_resolve_gene_node( $reconciliation, $args_ref );

        return $results_ref;
    }

    ##########################################################################
    # Usage      : $results_ref = $resolver->_resolve_species_nodes(
    #                  $reconciliation, $search_params_ref );
    #
    # Purpose    : Finds nodes in the gene tree that are related to the
    #              specified species nodes and edges.
    #
    # Returns    : The search results.
    #
    # Parameters : $reconciliation    - the reconciliation record.
    #              $search_params_ref - the orgiginal search parameters.
    #
    # Throws     : No exceptions.
    sub _resolve_species_nodes {
        my ( $self, $reconciliation, $search_params_ref ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the search parameters for all selected nodes.
        my @node_search_params
            = $self->_get_selected_species_tree_node_info($search_params_ref);

        # Look up the matching reconciliation nodes.
        my @results;
        for my $curr_params_ref (@node_search_params) {
            my $node_id       = $curr_params_ref->{'speciesTreeNode'};
            my $edge_selected = $curr_params_ref->{'edgeSelected'};
            my @nodes         = $dbh->resultset('ReconciliationNode')->search(
                {   'reconciliation_id'  => $reconciliation->id(),
                    'host_child_node_id' => $node_id,
                    'is_on_node'         => !$edge_selected,
                }
            );
            push @results,
                @{ $self->_format_results( $curr_params_ref, @nodes ) };
        }

        return \@results;
    }

    ##########################################################################
    # Usage      : @node_search_params
    #                  = $resolver->_get_selected_species_node_search_params(
    #                      $search_params_ref );
    #
    # Purpose    : Obtains the search parameters for all selected species tree
    #              nodes and edges.
    #
    # Returns    : A set of search parameters for all selected species tree
    #              nodes and edges.
    #
    # Parameters : $search_params_ref - the original search parameters.
    #
    # Throws     : No exceptions.
    sub _get_selected_species_tree_node_info {
        my ( $self, $search_params_ref ) = @_;

        # Extract the search parameters.
        my $species_node_id = $search_params_ref->{speciesTreeNode};
        my $edge_selected   = $search_params_ref->{edgeSelected};
        my $include_subtree = $search_params_ref->{includeSubtree};

        # There's no need to query if the subtree isn't selected.
        return ($search_params_ref) if !$include_subtree;

        # Find the subtree.
        my $dbh   = $dbh_of{ ident $self };
        my $rs    = $dbh->resultset('SpeciesTreeNode');
        my @nodes = eval { $rs->subtree($species_node_id) };
        if ( my $e = IPlant::TreeRec::NodeNotFoundException->caught() ) {
            return ($search_params_ref);
        }

        # Extract the bits of information we want from the results.
        my @results;
        for my $node (@nodes) {
            my $node_id = $node->id();
            if ( $node_id != $species_node_id || $edge_selected ) {
                push @results,
                    $self->_species_tree_node_search_params(
                    $search_params_ref, $node_id, 1 );
            }
            push @results,
                $self->_species_tree_node_search_params( $search_params_ref,
                $node_id, 0 );
        }

        return @results;
    }

    ##########################################################################
    # Usage      : my $search_params_ref
    #                  = $resolver->_species_tree_node_search_params(
    #                      $orig_params_ref, $node_id, $edge_selected );
    #
    # Purpose    : Builds search parameters for the selected species tree node
    #              ID and edge-selected flag.
    #
    # Returns    : A reference to the search parameters hash.
    #
    # Parameters : $orig_params_ref - the original search parameters.
    #              $node_id         - the node identifier.
    #              $edge_selected   - true if the leading edge is selected.
    #
    # Throws     : No exceptions.
    sub _species_tree_node_search_params {
        my ( $self, $orig_params_ref, $node_id, $edge_selected ) = @_;
        my %params = %{$orig_params_ref};
        $params{speciesTreeNode} = $node_id;
        $params{edgeSelected} = $edge_selected ? JSON::true : JSON::false;
        return \%params;
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
        my @nodes = $dbh->resultset('ReconciliationNode')->search(
            {   'reconciliation_id' => $reconciliation->id(),
                'node_id'           => $gene_node_id,
            }
        );

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

        # Format the results.
        my @results;
        for my $node (@nodes) {
            my %result = %{$search_params_ref};
            $result{speciesTreeNode} = $node->host_child_node_id();
            $result{geneTreeNode}    = $node->node_id();
            push @results, \%result;
        }

        return \@results;
    }
}

1;
__END__
