package IPlant::DB::TreeRec::ResultSet::SpeciesTree;

use warnings;
use strict;

use IPlant::TreeRec::X;

use base 'DBIx::Class::ResultSet';

##########################################################################
# Usage      : $species_tree = $dbh->resultset('SpeciesTree')
#                  ->for_name($tree_name);
#
# Purpose    : Finds the species tree with the given name.
#
# Returns    : The species tree.
#
# Parameters : $tree_name - the name of the species tree.
#
# Throws     : IPlant::TreeRec::TreeNotFoundException.
sub for_name {
    my ( $self, $tree_name ) = @_;

    # Find the tree.
    my $tree = $self->find( { 'species_tree_name' => $tree_name });
    IPlant::TreeRec::TreeNotFoundException->throw(
        error => "no species tree with name, $tree_name, found" )
        if !defined $tree;

    return $tree;
}

1;
__END__
