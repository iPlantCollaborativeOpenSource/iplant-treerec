package IPlant::DB::TreeRec::Result::CvtermDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::CvtermDbxref

=cut

__PACKAGE__->table("cvterm_dbxref");

=head1 ACCESSORS

=head2 cvterm_dbxref_id

  data_type: 'integer'
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_nullable: 0

=head2 is_for_definition

  data_type: 'tinyint'
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cvterm_dbxref_id",
  { data_type => "integer", is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_nullable => 0 },
  "is_for_definition",
  { data_type => "tinyint", is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cvterm_dbxref_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zKjbvK9D6uDj7QoNNsoEww


# You can replace this text with custom content, and it will be preserved on regeneration
1;
