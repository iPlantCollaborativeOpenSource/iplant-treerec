package IPlant::DB::TreeRec::Result::SpeciesCount;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table("species_tree_node");
__PACKAGE__->add_columns(
    "species_count",
    {   data_type     => "INTEGER",
        default_value => undef,
        is_nullable   => 0,
        size          => 10
    },
);

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'END_OF_DEFINITION');
SELECT COUNT(*) AS species_count
FROM species_tree_node parent
WHERE species_tree_id = ?
AND NOT EXISTS (
    SELECT *
    FROM species_tree_node child
    WHERE child.parent_id = parent.species_tree_node_id
)
END_OF_DEFINITION

1;
__END__

=head1 NAME

IPlant::DB::TreeRec::Result::SpeciesCount – counts the number of species in
the species tree with the given name.

=head1 ACCESSORS

=head2 species_count

  data_type: 'integer'
  is_nullable: 0
  size: 10

=cut
