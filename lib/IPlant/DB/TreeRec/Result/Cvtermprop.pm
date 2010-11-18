package IPlant::DB::TreeRec::Result::Cvtermprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::Cvtermprop

=cut

__PACKAGE__->table("cvtermprop");

=head1 ACCESSORS

=head2 cvtermprop_id

  data_type: 'integer'
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_nullable: 0

=head2 rank

  data_type: 'tinyint'
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cvtermprop_id",
  { data_type => "integer", is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_nullable => 0 },
  "rank",
  { data_type => "tinyint", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cvtermprop_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AoEUS3YGpSK8Xzs7u2viiQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
