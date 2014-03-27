package IPlant::TreeRec::TreeDataFormatter;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Bio::Tree::NodeNHX;
use Bio::TreeIO;
use Carp;
use Class::Std::Utils;
use JSON;
use Readonly;

{
    my %dbh_of;
    my %tree_of;
    my %tree_type_of;
    my %reconciliation_of;

    ##########################################################################
    # Usage      : $formatter = $IPlant::TreeRec::TreeDataFormatter->new(
    #                  {   'dbh'            => $dbh,
    #                      'tree'           => $tree,
    #                      'tree_type'      => $tree_type,
    #                      'reconciliation' => $reconciliation,
    #                  }
    #              );
    #
    # Purpose    : Initializes a new tree data formatter.
    #
    # Returns    : The new formatter.
    #
    # Parameters : $dbh            - the database handle.
    #              $tree           - the tree.
    #              $tree_type      - the type of the tree.
    #              $reconciliation - the reconciliation.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $dbh            = $args_ref->{dbh};
        my $tree           = $args_ref->{tree};
        my $tree_type      = $args_ref->{tree_type};
        my $reconciliation = $args_ref->{reconciliation};

        # Create the new object.
        my $self = bless anon_scalar, $class;

        # Initialize the object properties.
        $dbh_of{ ident $self }            = $dbh;
        $tree_of{ ident $self }           = $tree;
        $tree_type_of{ ident $self }      = $tree_type;
        $reconciliation_of{ ident $self } = $reconciliation;

        return $self;
    }

    ##########################################################################
    # Usage      : $data_ref = $formatter->format_tree();
    #
    # Purpose    : Formats the tree as a Perl data structure consisting of
    #              nested hashes.
    #
    # Returns    : The data structure representing the tree.
    #
    # Parameters : None.
    #
    # Throws     : No exceptions.
    sub format_tree {
        my ($self) = @_;

        # Extract the tree.
        my $tree = $tree_of{ ident $self };

        # Build and return the tree.
        return {
            'tree' => {
                'id'   => int $tree->id(),
                'root' => $self->_build_node( $tree->get_root_node() ),
            },
        };
    }

    ##########################################################################
    # Usage      : $root_ref = $formatter->_build_node($root);
    #
    # Purpose    : Builds the output for a single tree node.
    #
    # Returns    : The formatted node.
    #
    # Parameters : $node - the node.
    #
    # Throws     : No exceptions.
    sub _build_node {
        my ( $self, $node ) = @_;

        # Build the list of children.
        my @children;
        for my $child ( $node->each_Descendent() ) {
            push @children, $self->_build_node($child);
        }

        # Build the formatted node.
        my $formatted_node = {
            'id'       => int scalar $node->get_tag_values('ID'),
            'children' => \@children,
        };

        # Add the name if there is one.
        my $name = $node->id();
        if ( defined $name ) {
            $formatted_node->{name} = $name;
        }

        # Add the values of any NHX tags that we support.
        $self->_add_supported_tags( $node, $formatted_node );

        # Add the node metadata.
        $self->_add_node_metadata($formatted_node);

        return $formatted_node;
    }

    ##########################################################################
    # Usage      : $formatter->_add_node_metadata($formatted_node);
    #
    # Purpose    : Adds any metadata that we require to the node.
    #
    # Returns    : Nothing.
    #
    # Parameters : $formatted_node - the partially formatted tree node.
    #
    # Throws     : No exceptions.
    sub _add_node_metadata {
        my ( $self, $formatted_node ) = @_;

        # Extract the properties we need.
        my $dbh            = $dbh_of{ ident $self };
        my $tree_type      = $tree_type_of{ ident $self };
        my $reconciliation = $reconciliation_of{ ident $self };

        # Don't bother doing this if we don't have the information we need.
        return if !defined $dbh;
        return if !defined $tree_type;
        return if !defined $reconciliation;

        # Add the metadata for the type of tree that we're formatting.
        if ( $tree_type eq 'species' ) {
            $self->_add_species_node_metadata($formatted_node);
        }
        else {
            $self->_add_protein_node_metadata($formatted_node);
        }

        return;
    }

    ##########################################################################
    # Usage      : $formatter->_add_species_node_metadata($formatted_node);
    #
    # Purpose    : Adds any metadata that we require to a species tree node.
    #              Currently, no metadata are required.
    #
    # Returns    : Nothing.
    #
    # Parameters : $formatted_node - the partially formatted tree node.
    #
    # Throws     : No exceptions.
    sub _add_species_node_metadata {
        my ( $self, $formatted_node ) = @_;
        return;
    }

    ##########################################################################
    # Usage      : $formatter->_add_protein_node_metadata($formatted_node);
    #
    # Purpose    : Adds any metadata that we require to a protein tree node.
    #
    # Returns    : Nothing.
    #
    # Parameters : $formatted_node - the partially formatted tree node.
    #
    # Throws     : No exceptions.
    sub _add_protein_node_metadata {
        my ( $self, $formatted_node ) = @_;

        # Extract the properties we need.
        my $dbh            = $dbh_of{ ident $self };
        my $reconciliation = $reconciliation_of{ ident $self };

        # Look up the reconciliation node.
        my $reconciliation_node = $dbh->resultset('ReconciliationNode')->find(
            {   'reconciliation_id' => $reconciliation->id(),
                'node_id'           => $formatted_node->{id},
            }
        );

        # Build the metadata.
        $formatted_node->{metadata}{isSpeciation}
            = $reconciliation_node->is_on_node() ? JSON::true : JSON::false;

        return;
    }

    # The NHX tags that we support, indexed by the corresponding field name.
    Readonly my %NHX_TAG_FOR => {
        'edgeDuplications' => [ 'EDGEDUPS', 'scalar' ],
        'nodeDuplications' => [ 'NODEDUPS', 'scalar' ],
        'edgeRelatedNodes' => [ 'ERN',      'array' ],
        'nodeRelatedNodes' => [ 'NRN',      'array' ],
        'nodeRelatedEdges' => [ 'NRE',      'array' ],
        'sourceIdentifier' => [ 'SOURCEID', 'scalar' ],
    };

    ##########################################################################
    # Usage      : $formatter->_add_supported_tags( $node, $formatted_node );
    #
    # Purpose    : Adds the values of supported NHX tags to a formatted node.
    #
    # Returns    : Nothing.
    #
    # Parameters : $node           - the node from the actual tree.
    #              $formatted_node - the formatted node.
    #
    # Throws     : No exceptions.
    sub _add_supported_tags {
        my ( $self, $node, $formatted_node ) = @_;

        # Add any NHX tags that we support.
        for my $field_name ( keys %NHX_TAG_FOR ) {
            my ( $tag_name, $tag_type ) = @{ $NHX_TAG_FOR{$field_name} };
            my $field_value
                = $tag_type eq 'scalar'
                ? $self->_get_scalar_tag_value( $node, $tag_name )
                : $self->_get_array_tag_value( $node, $tag_name );
            if ( defined $field_value ) {
                $formatted_node->{$field_name} = $field_value;
            }
        }

        return;
    }

    ##########################################################################
    # Usage      : $value = $formatter->_get_scalar_tag_value( $node,
    #                  $tag_name );
    #
    # Purpose    : Extracts the value of a tag for which a scalar value is
    #              expected.
    #
    # Returns    : The tag value or undef if the tag isn't defined.
    #
    # Parameters : $node     - the node to get the tag value from.
    #              $tag_name - the name of the tag.
    #
    # Throws     : No exceptions.
    sub _get_scalar_tag_value {
        my ( $self, $node, $tag_name ) = @_;
        return scalar $node->get_tag_values($tag_name);
    }

    ##########################################################################
    # Usage      : $array_ref = $formatter->_get_scalar_tag_value( $node,
    #                  $tag_name );
    #
    # Purpose    : Extracts the value of a tag for which an array value is
    #              expected.
    #
    # Returns    : A reference to an array containing the values or undef if
    #              the tag isn't defined.
    #
    # Parameters : $node     - the node to get the tag value from.
    #              $tag_name - the name of the tag.
    #
    # Throws     : No exceptions.
    sub _get_array_tag_value {
        my ( $self, $node, $tag_name ) = @_;
        my @values = $node->get_tag_values($tag_name);
        return scalar @values > 0 ? \@values : undef;
    }
}

1;
__END__
