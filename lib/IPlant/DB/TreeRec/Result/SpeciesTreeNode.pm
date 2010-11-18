package IPlant::DB::TreeRec::Result::SpeciesTreeNode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::SpeciesTreeNode

=cut

__PACKAGE__->table("species_tree_node");

=head1 ACCESSORS

=head2 species_tree_node_id

  data_type: 'integer'
  is_nullable: 0

=head2 species_tree_id

  data_type: 'integer'
  is_nullable: 0

=head2 parent_id

  data_type: 'integer'
  is_nullable: 0

=head2 label

  data_type: 'text'
  is_nullable: 1

=head2 left_index

  data_type: 'integer'
  is_nullable: 0

=head2 right_index

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "species_tree_node_id",
  { data_type => "integer", is_nullable => 0 },
  "species_tree_id",
  { data_type => "integer", is_nullable => 0 },
  "parent_id",
  { data_type => "integer", is_nullable => 0 },
  "label",
  { data_type => "text", is_nullable => 1 },
  "left_index",
  { data_type => "integer", is_nullable => 0 },
  "right_index",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("species_tree_node_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xQYzaEX/cnBaMc4mELtLhg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
