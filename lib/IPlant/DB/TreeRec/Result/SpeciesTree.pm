package IPlant::DB::TreeRec::Result::SpeciesTree;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::SpeciesTree

=cut

__PACKAGE__->table("species_tree");

=head1 ACCESSORS

=head2 species_tree_id

  data_type: 'integer'
  is_nullable: 0

=head2 species_tree_name

  data_type: 'text'
  is_nullable: 1

=head2 root_node_id

  data_type: 'integer'
  is_nullable: 1

=head2 version

  data_type: 'smallint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "species_tree_id",
  { data_type => "integer", is_nullable => 0 },
  "species_tree_name",
  { data_type => "text", is_nullable => 1 },
  "root_node_id",
  { data_type => "integer", is_nullable => 1 },
  "version",
  { data_type => "smallint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("species_tree_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kBociQwZz6JJyMGhnmAQZQ

__PACKAGE__->has_many(
    nodes => "IPlant::DB::TreeRec::Result::SpeciesTreeNode",
    { "foreign.species_tree_id" => "self.species_tree_id" }
);
__PACKAGE__->belongs_to(
    root_node => "IPlant::DB::TreeRec::Result::SpeciesTreeNode",
    { "foreign.species_tree_node_id" => "self.root_node_id" }
);
__PACKAGE__->belongs_to(
    reconciliation => "IPlant::DB::TreeRec::Result::Reconciliation",
    { "foreign.species_tree_id" => "self.species_tree_id" }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
