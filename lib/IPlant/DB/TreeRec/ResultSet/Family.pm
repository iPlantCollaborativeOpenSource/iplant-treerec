package IPlant::DB::TreeRec::ResultSet::Family;

use warnings;
use strict;

use IPlant::TreeRec::X;

use base 'DBIx::Class::ResultSet';

##########################################################################
# Usage      : $family = $dbh->resultset('Family')
#                  ->for_name($family_name);
#
# Purpose    : Finds the gene family with the given name.
#
# Returns    : The family.
#
# Parameters : $family_name - the name of the gene family.
#
# Throws     : IPlant::TreeRec::GeneFamilyNotFoundException.
sub for_name {
    my ( $self, $family_name ) = @_;

    # Find the tree.
    my $family = $self->find( { 'stable_id' => $family_name });
    IPlant::TreeRec::GeneFamilyNotFoundException->throw(
        error => "no gene family with name, $family_name, found" )
        if !defined $family;

    return $family;
}

1;
__END__
