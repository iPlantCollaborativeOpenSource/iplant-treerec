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
    # Usage      : $gene_tree = $loader->load_gene_tree($family_name);
    #
    # Purpose    : Loads the gene tree for the given gene family name.
    #
    # Returns    : The gene tree.
    #
    # Parameters : $family_name - the gene family stable identifier.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub load_gene_tree {
        my ( $self, $family_name ) = @_;

        # Get the root node of the gene tree.
        my $dbh    = $dbh_of{ ident $self };
        my $family = $dbh->resultset('Family')
            ->find( { 'stable_id' => $family_name } );
        IPlant::TreeRec::GeneFamilyNotFound->throw()
            if !defined $family;
        my $db_tree = $family->protein_tree();
        IPlant::TreeRec::TreeNotFoundException->throw()
            if !defined $db_tree;
        my $root = $db_tree->root_node();

        # Build the tree.
        my $tree = Bio::Tree::Tree->new();
        $tree->set_root_node( $self->_build_gene_subtree($root) );
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
        $tree->set_root_node( $self->_build_species_subtree($root) );
        return $tree;
    }

    ##########################################################################
    # Usage      : $gene_tree = $loader->_build_gene_subtree($node);
    #
    # Purpose    : Builds the subtree rooted at the given node.
    #
    # Returns    : The subtree.
    #
    # Parameters : $node - the root node of the subtree to build.
    #
    # Throws     : No exceptions.
    sub _build_gene_subtree {
        my ( $self, $node ) = @_;

        # Build the node that will actually go in the tree.
        my $tree_node = $self->_build_gene_tree_node($node);

        # Add the subtrees rooted at each child node.
        for my $child ( $node->children() ) {
            $tree_node->add_Descendent( $self->_build_gene_subtree($child) );
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

    # Used to translate attribute values.
    Readonly my %ATTRIBUTE_TRANSLATOR_FOR =>
        ( D => sub { $_[0] ? 'Y' : 'N' }, );

    ##########################################################################
    # Usage      : $node = $loader->_build_gene_tree_node($database_node);
    #
    # Purpose    : Creates an instance of Bio::Tree::NodeNHX from the given
    #              instance of IPlant::DB::TreeRec::Result::ProteinTreeNode.
    #
    # Returns    : The new node.
    #
    # Parameters : $database_node - the ProteinTreeNode instance.
    #
    # Throws     : No exceptions.
    sub _build_gene_tree_node {
        my ( $self, $database_node ) = @_;

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

        # Add the ID attribute.
        $node->nhx_tag( { ID => $database_node->node_id() } );

        return $node;
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
}

1;
__END__
