package IPlant::DB::TreeRec::Result::ProteinTreeNode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';


=head1 NAME

IPlant::DB::TreeRec::Result::ProteinTreeNode

=cut

__PACKAGE__->table("protein_tree_node");

=head1 ACCESSORS

=head2 node_id

  data_type: 'integer'
  is_nullable: 0

=head2 protein_tree_id

  data_type: 'integer'
  is_nullable: 0

=head2 parent_id

  data_type: 'integer'
  is_nullable: 0

=head2 root_id

  data_type: 'integer'
  is_nullable: 0

=head2 clusterset_id

  data_type: 'integer'
  is_nullable: 0

=head2 left_index

  data_type: 'integer'
  is_nullable: 0

=head2 right_index

  data_type: 'integer'
  is_nullable: 0

=head2 distance_to_parent

  data_type: 'double precision'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "node_id",
  { data_type => "integer", is_nullable => 0 },
  "protein_tree_id",
  { data_type => "integer", is_nullable => 0 },
  "parent_id",
  { data_type => "integer", is_nullable => 0 },
  "root_id",
  { data_type => "integer", is_nullable => 0 },
  "clusterset_id",
  { data_type => "integer", is_nullable => 0 },
  "left_index",
  { data_type => "integer", is_nullable => 0 },
  "right_index",
  { data_type => "integer", is_nullable => 0 },
  "distance_to_parent",
  { data_type => "double precision", default_value => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("node_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-25 09:42:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yQcg2vVthlKdRAnahJn7Ww

__PACKAGE__->belongs_to(
    protein_tree => "IPlant::DB::TreeRec::Result::ProteinTree",
    { "foreign.protein_tree_id" => "self.protein_tree_id" }
);
__PACKAGE__->has_many(
    children => "IPlant::DB::TreeRec::Result::ProteinTreeNode",
    { "foreign.parent_id" => "self.node_id" }
);
__PACKAGE__->has_one(
    reconciliation_node => "IPlant::DB::TreeRec::Result::ReconciliationNode",
    { "foreign.node_id" => "self.node_id" }
);
__PACKAGE__->has_one(
    protein_tree_member => "IPlant::DB::TreeRec::Result::ProteinTreeMember",
    { "foreign.node_id" => "self.node_id" }
);
__PACKAGE__->has_many(
    attributes => "IPlant::DB::TreeRec::Result::ProteinTreeNodeAttribute",
    { "foreign.node_id" => "self.node_id" }
);

##########################################################################
# Usage      : $value = $node->get_attribute_value($attribute_name);
#
# Purpose    : Gets the value of the first attribute found with the given
#              attribute name.
#
# Returns    : The attribute value or undef if no such attribute is found.
#
# Parameters : $desired_name - the name of the attribute to search for.
#
# Throws     : No exceptions.
sub get_attribute_value {
    my ( $self, $desired_name ) = @_;
    for my $attribute ( $self->attributes() ) {
        my $current_name = $attribute->get_name();
        return $attribute->value()
            if defined $current_name && $current_name eq $desired_name;
    }
    return;
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
