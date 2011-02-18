package IPlant::DB::TreeRec::Result::ReconciliationAttribute;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::ReconciliationAttribute

=cut

__PACKAGE__->table("reconciliation_attribute");

=head1 ACCESSORS

=head2 reconciliation_attribute_id

  data_type: 'integer'
  is_nullable: 0

=head2 reconciliation_id

  data_type: 'integer'
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=head2 rank

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 source_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "reconciliation_attribute_id",
  { data_type => "integer", is_nullable => 0 },
  "reconciliation_id",
  { data_type => "integer", is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 0 },
  "rank",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "source_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("reconciliation_attribute_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-02-18 13:06:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8q3Q+tBQxaRVyTYbBSjsnA

our $VERSION = '0.0.2';

__PACKAGE__->belongs_to(
    reconciliation => "IPlant::DB::TreeRec::Result::Reconciliation",
    { "foreign.reconciliation_id" => "self.reconciliation_id" }
);
__PACKAGE__->has_one(
    cvterm => "IPlant::DB::TreeRec::Result::Cvterm",
    { "foreign.cvterm_id" => "self.cvterm_id" }
);

##########################################################################
# Usage      : my $name = $attr->get_name();
#
# Purpose    : Gets the name of the attribute.
#
# Returns    : The name of the attribute or undef if the attribute is
#              anonymous.
#
# Parameters : None.
#
# Throws     : No exceptions.
sub get_name {
    my ($self) = @_;
    my $cvterm = $self->cvterm();
    return if !defined $cvterm;
    return $cvterm->name();
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
