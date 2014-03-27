package IPlant::DB::TreeRec::ResultSet::ProteinTree;

use warnings;
use strict;

use IPlant::TreeRec::X;

use base 'DBIx::Class::ResultSet';

##########################################################################
# Usage      : $protein_tree = $dbh->resultset('ProteinTree')
#                  ->for_family_name($family_name);
#
# Purpose    : Finds the protein tree for the given gene family name.
#
# Returns    : The protein tree.
#
# Parameters : $family_name - the name of the gene family.
#
# Throws     : IPlant::TreeRec::TreeNotFoundException.
sub for_family_name {
    my ( $self, $family_name ) = @_;

    # Find the tree.
    my $tree = $self->find( { 'family.stable_id' => $family_name },
        { 'join' => 'family' } );
    IPlant::TreeRec::TreeNotFoundException->throw(
        error => "no protein tree found for family: $family_name" )
        if !defined $tree;

    return $tree;
}

1;
__END__
