package IPlant::DB::TreeRec::Result::ReconciliationNode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::ReconciliationNode

=cut

__PACKAGE__->table("reconciliation_node");

=head1 ACCESSORS

=head2 reconciliation_node_id

  data_type: 'integer'
  is_nullable: 0

=head2 reconciliation_id

  data_type: 'integer'
  is_nullable: 0

=head2 node_id

  data_type: 'integer'
  is_nullable: 0

=head2 host_parent_node_id

  data_type: 'integer'
  is_nullable: 1

=head2 host_child_node_id

  data_type: 'integer'
  is_nullable: 1

=head2 is_on_node

  data_type: 'tinyint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "reconciliation_node_id",
  { data_type => "integer", is_nullable => 0 },
  "reconciliation_id",
  { data_type => "integer", is_nullable => 0 },
  "node_id",
  { data_type => "integer", is_nullable => 0 },
  "host_parent_node_id",
  { data_type => "integer", is_nullable => 1 },
  "host_child_node_id",
  { data_type => "integer", is_nullable => 1 },
  "is_on_node",
  { data_type => "tinyint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("reconciliation_node_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6Jb05C5diSD64K0gOFy8Uw

__PACKAGE__->belongs_to(
    reconciliation => "IPlant::DB::TreeRec::Result::Reconciliation",
    { "foreign.reconciliation_id" => "self.reconciliation_id" }
);
__PACKAGE__->belongs_to(
    tree_node => "IPlant::DB::TreeRec::Result::ProteinTreeNode",
    { "foreign.node_id" => "self.node_id" }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
