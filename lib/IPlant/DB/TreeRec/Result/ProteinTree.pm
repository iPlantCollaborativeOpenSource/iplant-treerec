package IPlant::DB::TreeRec::Result::ProteinTree;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';

=head1 NAME

IPlant::DB::TreeRec::Result::ProteinTree

=cut

__PACKAGE__->table("protein_tree");

=head1 ACCESSORS

=head2 protein_tree_id

  data_type: 'integer'
  is_nullable: 0

=head2 family_id

  data_type: 'integer'
  is_nullable: 0

=head2 root_node_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "protein_tree_id", { data_type => "integer", is_nullable => 0 },
    "family_id",       { data_type => "integer", is_nullable => 0 },
    "root_node_id",    { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("protein_tree_id");

# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sH1nI0G3YJU+RazMybUdfg

__PACKAGE__->belongs_to(
    family => "IPlant::DB::TreeRec::Result::Family",
    { "foreign.family_id" => "self.family_id" }
);
__PACKAGE__->has_many(
    nodes => "IPlant::DB::TreeRec::Result::ProteinTreeNode",
    { "foreign.protein_tree_id" => "self.protein_tree_id" }
);
__PACKAGE__->has_one(
    root_node => "IPlant::DB::TreeRec::Result::ProteinTreeNode",
    { "foreign.node_id" => "self.root_node_id" }
);
__PACKAGE__->belongs_to(
    reconciliation => "IPlant::DB::TreeRec::Result::Reconciliation",
    { "foreign.protein_tree_id" => "self.protein_tree_id" }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
