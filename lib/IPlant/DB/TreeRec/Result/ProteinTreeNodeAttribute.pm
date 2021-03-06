package IPlant::DB::TreeRec::Result::ProteinTreeNodeAttribute;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::ProteinTreeNodeAttribute

=cut

__PACKAGE__->table("protein_tree_node_attribute");

=head1 ACCESSORS

=head2 protein_node_attribute_id

  data_type: 'integer'
  is_nullable: 0

=head2 node_id

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
  is_nullable: 0

=head2 source_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "protein_node_attribute_id",
  { data_type => "integer", is_nullable => 0 },
  "node_id",
  { data_type => "integer", is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 0 },
  "rank",
  { data_type => "smallint", is_nullable => 0 },
  "source_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("protein_node_attribute_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KkKWUNe7O3FrEDYm475Pfw

__PACKAGE__->belongs_to(
    node => "IPlant::DB::TreeRec::Result::ProteinTreeNode",
    { "foreign.node_id" => "self.node_id" }
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
