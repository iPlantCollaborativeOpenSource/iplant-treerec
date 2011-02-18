package IPlant::DB::TreeRec::ResultSet::ReconciliationAttribute;

use warnings;
use strict;

use IPlant::TreeRec::X;

use base 'DBIx::Class::ResultSet';

##########################################################################
# Usage      : @values = $dbh->resultset('ReconciliationAttribute')
#                  ->get_values( $reconciliation_id, $attribute_name );
#
# Purpose    : Retrieves the attribute values for all attributes of the
#              reconciliation with the given ID that have the given name.
#
# Returns    : The list of values.
#
# Parameters : $reconciliation_id - the reconciliation identifier.
#              $attribute_name    - the name of the attribute.
#
# Throws     : No exceptions.
sub get_values {
    my ( $self, $reconciliation_id, $attribute_name ) = @_;

    # Find the tree.
    my @results = $self->search(
        {   'reconciliation_id' => $reconciliation_id,
            'cvterm.name'       => $attribute_name,
        },
        { 'join' => 'cvterm' }
    );

    return map { $_->value() } @results;
}

1;
__END__
