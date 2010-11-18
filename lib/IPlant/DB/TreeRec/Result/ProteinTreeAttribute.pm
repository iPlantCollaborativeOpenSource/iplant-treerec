package IPlant::DB::TreeRec::Result::ProteinTreeAttribute;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::ProteinTreeAttribute

=cut

__PACKAGE__->table("protein_tree_attribute");

=head1 ACCESSORS

=head2 protein_tree_attribute_id

  data_type: 'integer'
  is_nullable: 0

=head2 protein_tree_id

  data_type: 'integer'
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=head2 rank

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 source_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "protein_tree_attribute_id",
  { data_type => "integer", is_nullable => 0 },
  "protein_tree_id",
  { data_type => "integer", is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 0 },
  "rank",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "source_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("protein_tree_attribute_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hO4I0ruAb+ZCU5byZn1lhA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
