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
    # Throws     : No exceptions.
    sub load_gene_tree {
        my ( $self, $family_name ) = @_;

        # Get the root node of the gene tree.
        my $dbh = $dbh_of{ ident $self };
        my $root
            = $dbh->resultset('Family')
            ->find( { 'stable_id' => $family_name } )->protein_tree()
            ->root_node();

        # Build the tree.
        my $tree = Bio::Tree::Tree->new();
        $tree->set_root_node( $self->_build_subtree($root) );
        return $tree;
    }

    ##########################################################################
    # Usage      : $gene_tree = $loader->_build_subtree($node);
    #
    # Purpose    : Builds the subtree rooted at the given node.
    #
    # Returns    : The subtree.
    #
    # Parameters : $node - the root node of the subtree to build.
    #
    # Throws     : No exceptions.
    sub _build_subtree {
        my ( $self, $node ) = @_;

        # Build the node that will actually go in the tree.
        my $tree_node = $self->_build_tree_node($node);

        # Add the subtrees rooted at each child node to this node.
        for my $child ( $node->children() ) {
            $tree_node->add_Descendent( $self->_build_subtree($child) );
        }

        return $tree_node;
    }

    # Used to translate attribute values.
    Readonly my %ATTRIBUTE_TRANSLATOR_FOR => (
        D => sub { $_[0] ? 'Y' : 'N' },
    );

    ##########################################################################
    # Usage      : $node = $loader->_build_tree_node($database_node);
    #
    # Purpose    : Creates an instance of Bio::Tree::NodeNHX from the given
    #              instance of IPlant::DB::TreeRec::Result::ProteinTreeNode.
    #
    # Returns    : The new node.
    #
    # Parameters : $database_node - the ProteinTreeNode instance.
    #
    # Throws     : No exceptions.
    sub _build_tree_node {
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
        for my $attr ( $database_node->attributes() ) {
            my $attr_name = $attr->get_name();
            my $attr_value = $attr->value();
            if ( defined $attr_name && defined $attr_value ) {
                my $translator_ref = $ATTRIBUTE_TRANSLATOR_FOR{$attr_name};
                if ( defined $translator_ref ) {
                    $attr_value = $translator_ref->($attr_value);
                }
                $node->nhx_tag( { $attr_name => $attr_value } );
            }
        }

        # Add the species annotation if this node has one.
        my $species = $database_node->get_attribute_value('S');
        if ( defined $species ) {
            $node->nhx_tag( { S => $species } );
        }

        return $node;
    }
}

1;
__END__
