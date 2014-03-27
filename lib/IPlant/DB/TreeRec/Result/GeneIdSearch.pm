package IPlant::DB::TreeRec::Result::GeneIdSearch;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table("family");
__PACKAGE__->add_columns(
    "name",
    {   data_type     => "VARCHAR",
        default_value => undef,
        is_nullable   => 0,
        size          => 64
    },
    "gene_id",
    {   data_type     => "VARCHAR",
        default_value => "",
        is_nullable   => 0,
        size          => 64
    },
);

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'END_OF_DEFINITION');
SELECT
    family.stable_id AS name,
    member.stable_id AS gene_id
FROM family
LEFT JOIN family_member ON family.family_id = family_member.family_id
LEFT JOIN member ON family_member.member_id = member.member_id
WHERE member.stable_id = ?
END_OF_DEFINITION

1;
__END__

=head1 NAME

IPlant::DB::TreeRec::Result::GeneIdSearch – searches for gene families by gene
identifier.

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 gene_id

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=cut
