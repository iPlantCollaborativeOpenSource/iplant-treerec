package IPlant::DB::TreeRec::Result::Family;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::Family

=cut

__PACKAGE__->table("family");

=head1 ACCESSORS

=head2 family_id

  data_type: 'integer'
  is_nullable: 0

=head2 stable_id

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 version

  data_type: 'integer'
  is_nullable: 1

=head2 method_link_species_set_id

  data_type: 'integer'
  is_nullable: 1

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 description_score

  data_type: 'double precision'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "family_id",
  { data_type => "integer", is_nullable => 0 },
  "stable_id",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "version",
  { data_type => "integer", is_nullable => 1 },
  "method_link_species_set_id",
  { data_type => "integer", is_nullable => 1 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "description_score",
  { data_type => "double precision", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("family_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ltDtnRPEZ0WhycUz18LRNQ

__PACKAGE__->has_one(
    protein_tree => "IPlant::DB::TreeRec::Result::ProteinTree",
    { "foreign.family_id" => "self.family_id" }
);
__PACKAGE__->has_many(
    family_member => "IPlant::DB::TreeRec::Result::FamilyMember",
    { "foreign.family_id" => "self.family_id" }
);
__PACKAGE__->many_to_many( members => 'family_member', 'member' );

# You can replace this text with custom content, and it will be preserved on regeneration
1;
