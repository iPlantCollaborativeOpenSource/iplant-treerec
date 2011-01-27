package IPlant::TreeRec::DatabaseTreeLoader;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Carp;
use Class::Std::Utils;
use Readonly;

{
    my %dbh_of;

    ##########################################################################
    # Usage      : $loader = IPlant::TreeRec::DatabaseTreeLoader->new($dbh);
    #
    # Purpose    : Initializes a new tree loader with the given database
    #              handle.
    #
    # Returns    : The new tree loader.
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
    # Usage      : $gene_tree = $loader->load_gene_tree( $family_name,
    #                  $species_tree_name );
    #
    # Purpose    : Loads the gene tree for the given gene family name,
    #              including reconciliation information if the name of the
    #              species tree is provided.
    #
    # Returns    : The gene tree.
    #
    # Parameters : $family_name       - the gene family stable identifier.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub load_gene_tree {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Get the protein tree from the database.
        my $db_tree = $self->_get_protein_tree($family_name);

        # Get the root node of the protein tree.
        my $root = $db_tree->root_node();

        # Get the reconciliation ID if the species tree name was provided.
        my $reconciliation;
        if ( defined $species_tree_name ) {
            my $species_tree = $self->_get_species_tree($species_tree_name);
            $reconciliation
                = $self->_get_reconciliation( $species_tree, $db_tree );
        }

        # Build the tree.
        my $tree = Bio::Tree::Tree->new();
        $tree->id( $db_tree->protein_tree_id() );
        $tree->set_root_node(
            $self->_build_gene_subtree( $root, $reconciliation ) );

        return $tree;
    }

    ##########################################################################
    # Usage      : $species_tree = $loader->load_species_tree($tree_name);
    #
    # Purpose    : Loads the species tree with the given tree name.
    #
    # Returns    : The species tree.
    #
    # Parameters : $tree_name - the name of the tree to load.
    #
    # Throws     : IPlant::TreeRec::TreeNotFoundException
    sub load_species_tree {
        my ( $self, $tree_name ) = @_;

        # Fetch the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the root node of the species tree.
        my $db_tree = $dbh->resultset('SpeciesTree')
            ->find( { 'species_tree_name' => $tree_name } );
        IPlant::TreeRec::TreeNotFoundException->throw()
            if !defined $db_tree;
        my $root = $db_tree->root_node();

        # Build the tree.
        my $tree = Bio::Tree::Tree->new();
        $tree->id( $db_tree->species_tree_id() );
        $tree->set_root_node( $self->_build_species_subtree($root) );
        return $tree;
    }

    ##########################################################################
    # Usage      : $gene_tree = $loader->_build_gene_subtree( $node,
    #                  $reconciliation );
    #
    # Purpose    : Builds the subtree rooted at the given node.  If a
    #              reconciliation is provided then the corresponding node
    #              identifiers in the corresponding species tree will be
    #              included in the tree.
    #
    # Returns    : The subtree.
    #
    # Parameters : $node           - the root node of the subtree to build.
    #              $reconciliation - the reconciliation between the gene tree
    #                                and the species tree.
    #
    # Throws     : No exceptions.
    sub _build_gene_subtree {
        my ( $self, $node, $reconciliation ) = @_;

        # Build the node that will actually go in the tree.
        my $tree_node
            = $self->_build_gene_tree_node( $node, $reconciliation );

        # Add the subtrees rooted at each child node.
        for my $child ( $node->children() ) {
            $tree_node->add_Descendent(
                $self->_build_gene_subtree( $child, $reconciliation ) );
        }

        return $tree_node;
    }

    ##########################################################################
    # Usage      : $species_tree = $loader->_build_species_subtree($node);
    #
    # Purpose    : Builds the subtree rooted at the given node.
    #
    # Returns    : The subtree.
    #
    # Parameters : $node - the root node of the subtree to build.
    #
    # Throws     : No exceptions.
    sub _build_species_subtree {
        my ( $self, $node ) = @_;

        # Build the node that will actually go in the tree.
        my $tree_node = $self->_build_species_tree_node($node);

        # Add the subtrees rooted at each child node.
        for my $child ( $node->children() ) {
            $tree_node->add_Descendent(
                $self->_build_species_subtree($child) );
        }

        return $tree_node;
    }

    ##########################################################################
    # Usage      : $node = $loader->_build_gene_tree_node( $database_node,
    #                  $reconciliation );
    #
    # Purpose    : Creates an instance of Bio::Tree::NodeNHX from the given
    #              instance of IPlant::DB::TreeRec::Result::ProteinTreeNode.
    #              If a reconciliation is provided then the identifier of the
    #              corresponding nodes in the species tree will also be
    #              noted in the tree.
    #
    # Returns    : The new node.
    #
    # Parameters : $database_node - the ProteinTreeNode instance.
    #
    # Throws     : No exceptions.
    sub _build_gene_tree_node {
        my ( $self, $database_node, $reconciliation ) = @_;

        # Create the new node.
        my $node = Bio::Tree::NodeNHX->new();

        # Determine the displayable node ID.
        my $protein_tree_member = $database_node->protein_tree_member();
        my $id
            = defined $protein_tree_member
            ? $protein_tree_member->member()->stable_id()
            : $node->id();
        $node->id($id);

        # Add any attributes that are associated with the node.
        $self->_add_gene_tree_node_attributes( $node, $database_node );

        # Add the ID attribute.
        $node->nhx_tag( { ID => $database_node->node_id() } );

        # Add any related species tree node ids if we have a reconciliation.
        if ( defined $reconciliation ) {
            $self->_add_species_tree_node_ids( $reconciliation, $node );
        }

        return $node;
    }

    ##########################################################################
    # Usage      : $loader->_add_species_tree_node_ids( $reconciliation,
    #                  $node );
    #
    # Purpose    : Adds the species tree node IDs to the given tree node.
    #
    # Returns    : Nothing.
    #
    # Parameters : $reconciliation - the tree reconciliation object.
    #              $node           - the tree node.
    #
    # Throws     : No exceptions.
    sub _add_species_tree_node_ids {
        my ( $self, $reconciliation, $node ) = @_;

        # Fetch the internal node ID.
        my $node_id = int scalar $node->get_tag_values('ID');

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the reconciliation node.
        my $reconciliation_node = $dbh->resultset('ReconciliationNode')->find(
            {   'reconciliation_id' => $reconciliation->id(),
                'node_id'           => $node_id,
            }
        );
        return if !defined $reconciliation_node;

        # Extract the information we want from the reconciliation node.
        my $parent_id  = $reconciliation_node->host_parent_node_id();
        my $child_id   = $reconciliation_node->host_child_node_id();
        my $is_on_node = $reconciliation_node->is_on_node();

        # Skip reconciliation nodes we don't care about.
        return if !defined $parent_id && !$is_on_node;
        return if !defined $child_id;

        # Add the tag to the node
        my $related_nodes_ref
            = $is_on_node ? [$child_id] : [ $parent_id, $child_id ];
        $node->nhx_tag( { 'RTN' => $related_nodes_ref } );

        return;
    }

    # Used to translate attribute values.
    Readonly my %ATTRIBUTE_TRANSLATOR_FOR =>
        ( D => sub { $_[0] ? 'Y' : 'N' }, );

    ##########################################################################
    # Usage      : $loader->_add_gene_tree_node_attributes( $node,
    #                  $database_node );
    #
    # Purpose    : Adds any supported NHX attributes to the tree node.
    #
    # Returns    : Nothing.
    #
    # Parameters : $node          - the node being added to the tree.
    #              $database_node - the node retrieved from the database.
    #
    # Throws     : No exceptions.
    sub _add_gene_tree_node_attributes {
        my ( $self, $node, $database_node ) = @_;

        ATTR:
        for my $attr ( $database_node->attributes() ) {
            my $attr_name = $attr->get_name();
            next ATTR if !defined $attr_name || $attr_name eq 'ID';
            my $attr_value = $attr->value();
            next ATTR if !defined $attr_value;
            my $translator_ref = $ATTRIBUTE_TRANSLATOR_FOR{$attr_name};
            if ( defined $translator_ref ) {
                $attr_value = $translator_ref->($attr_value);
            }
            $node->nhx_tag( { $attr_name => $attr_value } );
        }

        return;
    }

    ##########################################################################
    # Usage      : $node = $loader->_build_species_tree_node($database_node);
    #
    # Purpose    : Creates an instance of Bio::Tree::NodeNHX from the given
    #              instance of IPlant::DB::TreeRec::Result::SpeciesTreeNode.
    #
    # Returns    : The new node.
    #
    # Parameters : $database_node - the SpeciesTreeNode instance.
    #
    # Throws     : No exceptions.
    sub _build_species_tree_node {
        my ( $self, $database_node ) = @_;

        # Create the new node.
        my $node = Bio::Tree::NodeNHX->new();
        $node->id( $database_node->label() );

        # Add the ID attribute.
        my $node_id = $database_node->species_tree_node_id();
        $node->nhx_tag( { ID => $node_id } );

        # Add the duplication counts for the node.
        $node->nhx_tag( { EDGEDUPS => $self->_count_edge_dups($node_id) } );
        $node->nhx_tag( { NODEDUPS => $self->_count_node_dups($node_id) } );

        return $node;
    }

    ##########################################################################
    # Usage      : $count = $loader->_count_edge_dups($node_id);
    #
    # Purpose    : Counts the number of duplication events on the edge leading
    #              into the node with the given ID.
    #
    # Returns    : The number of duplication events.
    #
    # Parameters : $node_id - the ID of the node that the edge leads into.
    #
    # Throws     : No exceptions.
    sub _count_edge_dups {
        my ( $self, $node_id ) = @_;
        return $self->_count_dups( $node_id, 0 );
    }

    ##########################################################################
    # Usage      : $count = $loader->_count_node_dups($node_id);
    #
    # Purpose    : Counts the number of duplication events on the node with
    #              the given ID.
    #
    # Returns    : The number of duplication events.
    #
    # Parameters : $node_id - the ID of the node to check.
    #
    # Throws     : No exceptions.
    sub _count_node_dups {
        my ( $self, $node_id ) = @_;
        return $self->_count_dups( $node_id, 1 );
    }

    ##########################################################################
    # Usage      : $count = $loader->_count_dups( $node_id, $is_on_node );
    #
    # Purpose    : Counts the number of duplication events either on the node
    #              with the given ID or on the edge leading into that node.
    #              If $is_on_node is true then the duplication count for the
    #              node itself is returned.  Otherwise, the duplication count
    #              for the edge leading into the node is returned.
    #
    # Returns    : The number of duplications.
    #
    # Parameters : $node_id    - the ID of the node to check.
    #              $is_on_node - true if we should count duplications on the
    #                            node itself.
    #
    # Throws     : No exceptions.
    sub _count_dups {
        my ( $self, $node_id, $is_on_node ) = @_;

        # Count the edge duplications.
        my $dbh = $dbh_of{ ident $self };
        my $rs  = $dbh->resultset('ReconciliationNode')->search(
            {   -and => [
                    host_child_node_id  => $node_id,
                    host_parent_node_id => { '!=' => undef },
                    is_on_node          => $is_on_node,
                ],
            },
            {   columns  => [qw(reconciliation_id)],
                distinct => 1,
            },
        );

        return $rs->count();
    }

    ##########################################################################
    # Usage      : $tree = $loader->_get_protein_tree($family_name);
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

    ##########################################################################
    # Usage      : $species_tree = $loader->_get_species_tree(
    #                  $species_tree_name );
    #
    # Purpose    : Retrieves the species tree from the database.
    #
    # Returns    : The species tree.
    #
    # Parameters : $species_tree_name - the name of the species tree.
    #
    # Throws     : IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::ReconciliationNotFoundException
    sub _get_species_tree {
        my ( $self, $species_tree_name ) = @_;

        # Get the species tree.
        my $dbh          = $dbh_of{ ident $self };
        my $species_tree = $dbh->resultset('SpeciesTree')
            ->find( { 'species_tree_name' => $species_tree_name } );
        IPlant::TreeRec::TreeNotFoundException->throw()
            if !defined $species_tree;

        return $species_tree;
    }

    ##########################################################################
    # Usage      : $reconciliation = $loader->_get_reconciliation(
    #                  $species_tree, $protein_tree );
    #
    # Purpose    : Retrieves a reconciliation from the database.
    #
    # Returns    : The reconciliation.
    #
    # Parameters : $species_tree - the reconciled species tree.
    #              $protein_tree - the reconciled protein tree.
    #
    # Throws     : IPlant::TreeRec::ReconciliationNotFoundException
    sub _get_reconciliation {
        my ( $self, $species_tree, $protein_tree ) = @_;

        # Get the reconciliation.
        my $dbh            = $dbh_of{ ident $self };
        my $reconciliation = $dbh->resultset('Reconciliation')->find(
            {   'species_tree_id' => $species_tree->id(),
                'protein_tree_id' => $protein_tree->id()
            }
        );
        IPlant::TreeRec::ReconciliationNotFoundException->throw()
            if !defined $reconciliation;

        return $reconciliation;
    }
}

1;
__END__
