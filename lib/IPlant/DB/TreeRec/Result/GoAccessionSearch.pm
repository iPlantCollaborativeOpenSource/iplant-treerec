package IPlant::DB::TreeRec::Result::GoAccessionSearch;

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
    "go_accession",
    {   data_type     => "VARCHAR",
        default_value => "",
        is_nullable   => 0,
        size          => 255
    },
);

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'END_OF_DEFINITION');
SELECT
    family.stable_id  AS name,
    dbxref.accession  AS go_accession
FROM family
LEFT JOIN family_member ON family.family_id = family_member.family_id
LEFT JOIN member ON family_member.member_id = member.member_id
LEFT JOIN member_attribute ON member.member_id = member_attribute.member_id
LEFT JOIN cvterm ON member_attribute.cvterm_id = cvterm.cvterm_id
LEFT JOIN dbxref ON cvterm.dbxref_id = dbxref.dbxref_id
LEFT JOIN db ON dbxref.db_id = db.db_id
WHERE db.name = "GO" AND dbxref.accession = ?
GROUP BY family.family_id
END_OF_DEFINITION

1;
__END__

=head1 NAME

IPlant::DB::TreeRec::Result::GoAccessionSearch – searches for gene families by
GO accession.

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 go_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut
