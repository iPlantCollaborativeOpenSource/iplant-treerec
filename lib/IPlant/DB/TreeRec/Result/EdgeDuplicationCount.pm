package IPlant::DB::TreeRec::Result::EdgeDuplicationCount;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table("reconciliation_node");
__PACKAGE__->add_columns(
    "count",
    {   data_type     => "INTEGER",
        default_value => 0,
        is_nullable   => 0,
        size          => 8
    },
);

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'END_OF_DEFINITION');
SELECT COUNT(DISTINCT reconciliation_id)
FROM reconciliation_node
WHERE host_child_node_id = ? AND is_on_node IS FALSE
END_OF_DEFINITION

1;
__END__

=head1 NAME

IPlant::DB::TreeRec::Result::GeneIdSearch – counts duplication events on an
edge.

=head1 ACCESSORS

=head2 count

  data_type: 'integer'
  is_nullable: 0
  size: 8

=cut
