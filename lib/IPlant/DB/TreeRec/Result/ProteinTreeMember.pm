package IPlant::DB::TreeRec::Result::ProteinTreeMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::ProteinTreeMember

=cut

__PACKAGE__->table("protein_tree_member");

=head1 ACCESSORS

=head2 protein_tree_member_id

  data_type: 'integer'
  is_nullable: 0

=head2 node_id

  data_type: 'integer'
  is_nullable: 0

=head2 root_id

  data_type: 'integer'
  is_nullable: 0

=head2 member_id

  data_type: 'integer'
  is_nullable: 0

=head2 method_link_species_set_id

  data_type: 'integer'
  is_nullable: 0

=head2 cigar_line

  data_type: 'text'
  is_nullable: 1

=head2 cigar_start

  data_type: 'integer'
  is_nullable: 1

=head2 cigar_end

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "protein_tree_member_id",
  { data_type => "integer", is_nullable => 0 },
  "node_id",
  { data_type => "integer", is_nullable => 0 },
  "root_id",
  { data_type => "integer", is_nullable => 0 },
  "member_id",
  { data_type => "integer", is_nullable => 0 },
  "method_link_species_set_id",
  { data_type => "integer", is_nullable => 0 },
  "cigar_line",
  { data_type => "text", is_nullable => 1 },
  "cigar_start",
  { data_type => "integer", is_nullable => 1 },
  "cigar_end",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("protein_tree_member_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oNXAr9HCy+Qc/oASiILH3A

__PACKAGE__->belongs_to(
    node => "IPlant::DB::TreeRec::Result::ProteinTreeNode",
    { "foreign.node_id" => "self.node_id" }
);
__PACKAGE__->belongs_to(
    member => "IPlant::DB::TreeRec::Result::Member",
    { "foreign.member_id" => "self.member_id" }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
