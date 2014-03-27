package IPlant::DB::TreeRec::Result::FamilyAttribute;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::FamilyAttribute

=cut

__PACKAGE__->table("family_attribute");

=head1 ACCESSORS

=head2 family_attribute_id

  data_type: 'integer'
  is_nullable: 0

=head2 family_id

  data_type: 'integer'
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 source_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "family_attribute_id",
  { data_type => "integer", is_nullable => 0 },
  "family_id",
  { data_type => "integer", is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "source_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("family_attribute_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-02-18 13:06:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dVp/PYFH+DXedafqHvJOiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
