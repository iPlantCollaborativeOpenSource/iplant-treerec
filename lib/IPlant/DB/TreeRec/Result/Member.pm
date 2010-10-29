package IPlant::DB::TreeRec::Result::Member;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::Member

=cut

__PACKAGE__->table("member");

=head1 ACCESSORS

=head2 member_id

  data_type: 'integer'
  is_nullable: 0

=head2 stable_id

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 version

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 source_name

  accessor: undef
  data_type: 'char'
  is_nullable: 0
  size: 17

=head2 taxon_id

  data_type: 'integer'
  is_nullable: 0

=head2 genome_db_id

  data_type: 'integer'
  is_nullable: 1

=head2 sequence_id

  data_type: 'integer'
  is_nullable: 1

=head2 gene_member_id

  data_type: 'integer'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 chr_name

  data_type: 'char'
  is_nullable: 1
  size: 40

=head2 chr_start

  data_type: 'integer'
  is_nullable: 1

=head2 chr_end

  data_type: 'integer'
  is_nullable: 1

=head2 chr_strand

  data_type: 'tinyint'
  is_nullable: 0

=head2 display_label

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "member_id",
  { data_type => "integer", is_nullable => 0 },
  "stable_id",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "version",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "source_name",
  { accessor => undef, data_type => "char", is_nullable => 0, size => 17 },
  "taxon_id",
  { data_type => "integer", is_nullable => 0 },
  "genome_db_id",
  { data_type => "integer", is_nullable => 1 },
  "sequence_id",
  { data_type => "integer", is_nullable => 1 },
  "gene_member_id",
  { data_type => "integer", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "chr_name",
  { data_type => "char", is_nullable => 1, size => 40 },
  "chr_start",
  { data_type => "integer", is_nullable => 1 },
  "chr_end",
  { data_type => "integer", is_nullable => 1 },
  "chr_strand",
  { data_type => "tinyint", is_nullable => 0 },
  "display_label",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("member_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ViJVcHxDhW9kSjETjpH1qw

__PACKAGE__->has_one(
    protein_tree_member => "IPlant::DB::TreeRec::Result::ProteinTreeMember",
    { "foreign.member_id" => "self.member_id" }
);
__PACKAGE__->has_many(
    family_member => "IPlant::DB::TreeRec::Result::FamilyMember",
    { "foreign.member_id" => "self.member_id" }
);
__PACKAGE__->many_to_many( families => 'family_member', 'family' );

# You can replace this text with custom content, and it will be preserved on regeneration
1;
