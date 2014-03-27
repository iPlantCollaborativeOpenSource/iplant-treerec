package IPlant::DB::TreeRec::Result::Cvtermpath;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::Cvtermpath

=cut

__PACKAGE__->table("cvtermpath");

=head1 ACCESSORS

=head2 cvtermpath_id

  data_type: 'integer'
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_nullable: 0

=head2 subject_id

  data_type: 'integer'
  is_nullable: 0

=head2 object_id

  data_type: 'integer'
  is_nullable: 0

=head2 cv_id

  data_type: 'integer'
  is_nullable: 0

=head2 pathdistance

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cvtermpath_id",
  { data_type => "integer", is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_nullable => 0 },
  "subject_id",
  { data_type => "integer", is_nullable => 0 },
  "object_id",
  { data_type => "integer", is_nullable => 0 },
  "cv_id",
  { data_type => "integer", is_nullable => 0 },
  "pathdistance",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cvtermpath_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aiANc7jXU3HPTeeGa5g84g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
