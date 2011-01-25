package IPlant::DB::TreeRec::Result::DuplicationSearch;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table("family");
__PACKAGE__->add_columns(
    "name",
    {   data_type     => "VARCHAR",
        default_value => undef,
        is_nullable   => 0,
        size          => 64
    },
);

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'END_OF_DEFINITION');
SELECT DISTINCT family.stable_id AS name
FROM reconciliation_node
LEFT JOIN reconciliation ON reconciliation_node.reconciliation_id = reconciliation.reconciliation_id
LEFT JOIN protein_tree ON reconciliation.protein_tree_id = protein_tree.protein_tree_id
LEFT JOIN family ON protein_tree.family_id = family.family_id
WHERE reconciliation_node.host_child_node_id = ?
AND reconciliation_node.is_on_node = ?
END_OF_DEFINITION

1;
__END__

=head1 NAME

IPlant::DB::TreeRec::Result::GeneIdSearch – searches for the identifiers of
gene families that have duplication events at a specific spot in a species
tree.

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=cut
