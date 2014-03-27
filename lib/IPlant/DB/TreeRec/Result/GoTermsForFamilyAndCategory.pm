package IPlant::DB::TreeRec::Result::GoTermsForFamilyAndCategory;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table("family");
__PACKAGE__->add_columns(
    "go_term",
    {   data_type     => "VARCHAR",
        default_value => 0,
        is_nullable   => 0,
        size          => 950,
    },
    "count",
    {   data_type     => "INTEGER",
        default_value => 0,
        is_nullable   => 0,
        size          => 10,
    },
);

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'END_OF_DEFINITION');
SELECT cvterm.name AS go_term, COUNT(*) AS count
FROM protein_tree_node
LEFT JOIN protein_tree_member ON
protein_tree_node.node_id = protein_tree_member.node_id
LEFT JOIN member ON
protein_tree_member.member_id = member.member_id
LEFT JOIN member_attribute ON
member.member_id = member_attribute.member_id
LEFT JOIN cvterm ON
member_attribute.cvterm_id = cvterm.cvterm_id
LEFT JOIN dbxref ON
cvterm.dbxref_id = dbxref.dbxref_id
LEFT JOIN db ON
dbxref.db_id = db.db_id
LEFT JOIN cvtermpath ON
cvtermpath.subject_id = cvterm.cvterm_id
WHERE db.name = 'GO'
AND cvtermpath.object_id = ?
AND protein_tree_node.protein_tree_id = ?
GROUP BY go_term
ORDER BY count DESC
END_OF_DEFINITION

1;
__END__

=head1 NAME

IPlant::DB::TreeRec::Result::GoTermsForFamilyAndCategory – view for obtaining
the list of GO terms for a given gene family and GO term category.

=head1 ACCESSORS

=head2 go_term

  data_type: 'varchar'
  is_nullable: 0
  size: 950

=head2 count

  data_type: 'integer'
  is_nullable: 0
  size: 10

=cut
