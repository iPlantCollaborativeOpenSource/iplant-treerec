package IPlant::DB::TreeRec::ResultSet::SpeciesTreeNode;

use warnings;
use strict;

use IPlant::TreeRec::X;

use base 'DBIx::Class::ResultSet';

##########################################################################
# Usage      : $node = $dbh->resultset('SpeciesTreeNode')
#                  ->for_id($node_id);
#
# Purpose    : Obtains the species tree node with the given identifier.
#
# Returns    : The species tree node.
#
# Parameters : $node_id - the node identifier.
#
# Throws     : IPlant::TreeRec::NodeNotFoundException
sub for_id {
    my ( $self, $node_id ) = @_;

    # Fetch the node.
    my $node = $self->find( { 'species_tree_node_id' => $node_id } );
    IPlant::TreeRec::NodeNotFoundException->throw(
        error => "no species node found with identifier, $node_id" )
        if !defined $node;

    return $node;
}

##########################################################################
# Usage      : @nodes = $dbh->resultset('SpeciesTreeNode')
#                  ->subtree($root_node_id);
#
# Purpose    : Selects all of the nodes in the subtree rooted at the node
#              with the given identifier.  The root node is included in
#              the results.
#
# Returns    : The list of nodes.
#
# Parameters : $root_node_id - the ID of the root of the subtree.
#
# Throws     : IPlant::TreeRec::NodeNotFoundException
sub subtree {
    my ( $self, $root_node_id ) = @_;

    # Fetch the root node.
    my $root_node
        = $self->find( { 'species_tree_node_id' => $root_node_id } );
    IPlant::TreeRec::NodeNotFoundException->throw(
        error => "no species node found with identifier, $root_node_id" )
        if !defined $root_node;

    # Find all nodes in the subtree.
    my @nodes = $self->search(
        {   -and => [
                left_index  => { '>=' => $root_node->left_index() },
                right_index => { '<=' => $root_node->right_index() },
            ],
        }
    );

    return @nodes;
}

1;
__END__
