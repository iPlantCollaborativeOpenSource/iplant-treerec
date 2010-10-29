package IPlant::DB::TreeRec::Result::Reconciliation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::Reconciliation

=cut

__PACKAGE__->table("reconciliation");

=head1 ACCESSORS

=head2 reconciliation_id

  data_type: 'integer'
  is_nullable: 0

=head2 protein_tree_id

  data_type: 'integer'
  is_nullable: 0

=head2 species_tree_id

  data_type: 'integer'
  is_nullable: 0

=head2 species_set_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "reconciliation_id",
  { data_type => "integer", is_nullable => 0 },
  "protein_tree_id",
  { data_type => "integer", is_nullable => 0 },
  "species_tree_id",
  { data_type => "integer", is_nullable => 0 },
  "species_set_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("reconciliation_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YyKzyam+ePcAzF8KaWku2g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
