package IPlant::DB::TreeRec::Result::Dbxrefprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::Dbxrefprop

=cut

__PACKAGE__->table("dbxrefprop");

=head1 ACCESSORS

=head2 dbxrefprop_id

  data_type: 'integer'
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_nullable: 0

=head2 rank

  data_type: 'smallint'
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "dbxrefprop_id",
  { data_type => "integer", is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_nullable => 0 },
  "rank",
  { data_type => "smallint", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("dbxrefprop_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sq8aC1sFPN1+sG/EF33hSw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
