package IPlant::DB::TreeRec::Result::Sequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.1';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::Sequence

=cut

__PACKAGE__->table("sequence");

=head1 ACCESSORS

=head2 sequence_id

  data_type: 'integer'
  is_nullable: 0

=head2 length

  data_type: 'integer'
  is_nullable: 1

=head2 sequence

  accessor: undef
  data_type: 'longtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sequence_id",
  { data_type => "integer", is_nullable => 0 },
  "length",
  { data_type => "integer", is_nullable => 1 },
  "sequence",
  { accessor => undef, data_type => "longtext", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("sequence_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qNo0sCmm4Zu9zKJNVvl8mw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
