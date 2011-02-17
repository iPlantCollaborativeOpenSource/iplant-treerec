package IPlant::DB::TreeRec::Result::Duplications;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table("reconciliation_node");
__PACKAGE__->add_columns(
    "duplications",
    {   data_type     => "VARCHAR",
        default_value => undef,
        is_nullable   => 0,
        size          => 10
    },
);

__PACKAGE__->result_source_instance->is_virtual(1);


__PACKAGE__->result_source_instance->view_definition(<<'END_OF_DEFINITION');
SELECT reconciliation_node_id AS duplications
FROM reconciliation_node rn
JOIN protein_tree_node pn ON rn.node_id = pn.node_id
WHERE parent_id <> 0
AND reconciliation_id = ?
AND is_on_node IS FALSE
AND EXISTS (
    SELECT *
    FROM protein_tree_node child
    WHERE rn.node_id = child.parent_id
)
GROUP BY rn.node_id
END_OF_DEFINITION

1;
__END__

=head1 NAME

IPlant::DB::TreeRec::Result::Speciations â Returns all 
speciation events in the gene family with the given identifier.

=head1 ACCESSORS

=head2 speciations

  data_type: 'integer'
  is_nullable: 0
  size: 10

=cut
