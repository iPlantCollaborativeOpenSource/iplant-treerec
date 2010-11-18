package IPlant::DB::TreeRec::Result::FamilyMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::FamilyMember

=cut

__PACKAGE__->table("family_member");

=head1 ACCESSORS

=head2 family_id

  data_type: 'integer'
  is_nullable: 1

=head2 member_id

  data_type: 'integer'
  is_nullable: 1

=head2 cigar_line

  data_type: 'mediumtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "family_id",
  { data_type => "integer", is_nullable => 1 },
  "member_id",
  { data_type => "integer", is_nullable => 1 },
  "cigar_line",
  { data_type => "mediumtext", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CX3pR+pfiRj9aNFjmk3u/g

__PACKAGE__->belongs_to(
    member => "IPlant::DB::TreeRec::Result::Member",
    { "foreign.member_id" => "self.member_id" }
);
__PACKAGE__->belongs_to(
    family => "IPlant::DB::TreeRec::Result::Family",
    { "foreign.family_id" => "self.family_id" }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
