package IPlant::DB::TreeRec::Result::ProteinTreeNodePath;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::ProteinTreeNodePath

=cut

__PACKAGE__->table("protein_tree_node_path");

=head1 ACCESSORS

=head2 protein_tree_node_path_id

  data_type: 'integer'
  is_nullable: 0

=head2 parent_node_id

  data_type: 'integer'
  is_nullable: 0

=head2 child_node_id

  data_type: 'integer'
  is_nullable: 0

=head2 path

  data_type: 'text'
  is_nullable: 0

=head2 distance

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "protein_tree_node_path_id",
  { data_type => "integer", is_nullable => 0 },
  "parent_node_id",
  { data_type => "integer", is_nullable => 0 },
  "child_node_id",
  { data_type => "integer", is_nullable => 0 },
  "path",
  { data_type => "text", is_nullable => 0 },
  "distance",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("protein_tree_node_path_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-02-18 13:06:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ReRw7swpehfYfPsdfPtIxw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
