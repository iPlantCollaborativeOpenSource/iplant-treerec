package IPlant::DB::TreeRec::Result::SpeciesDuplicationsForFamily;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table("reconciliation_node");
__PACKAGE__->add_columns(
    "node_id",
    {   data_type     => "INTEGER",
        default_value => 0,
        is_nullable   => 0,
        size          => 10,
    },
    "count",
    {   data_type     => "INTEGER",
        default_value => 0,
        is_nullable   => 0,
        size          => 10,
    },
);

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'END_OF_DEFINITION');
SELECT 
host_child_node_id AS node_id,
count(*) AS count
FROM reconciliation_node rn
WHERE reconciliation_id = ?
AND is_on_node IS FALSE
GROUP BY host_child_node_id
END_OF_DEFINITION

1;
__END__

=head1 NAME

IPlant::DB::TreeRec::Result::DuplicationList â Searches for the species tree node id
corresponding to branches where duplications have occurred.
tree.

=head1 ACCESSORS

=head2 node_id

  data_type: 'integer'
  is_nullable: 0
  size: 64
  
  
=head2  count

  data_type: 'integer'
        is_nullable : 0,
        size: 10,

=cut
