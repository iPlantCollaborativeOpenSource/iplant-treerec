package IPlant::TreeRec::GeneFamilyInfo;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );
use Memoize;
use Readonly;

memoize( '_protein_tree_id_for_family' );
memoize( '_get_representative_go_term' );
memoize( '_get_go_category_id' );
memoize( '_count_go_terms' );
memoize( '_count_genes' );
memoize( '_count_duplications' );
memoize( '_count_speciations' );
memoize( '_count_species' );

# An empty gene family summary.
Readonly my %EMPTY_SUMMARY => (
    'gene_count'         => 0,
    'duplication_events' => 0,
    'speciation_events'  => 0,
    'species_count'      => 0,
    'go_term_count'      => 0,
);

{
    my %dbh_of;
    my %go_term_length_limit_of;
    my %go_categories_of;

    ##########################################################################
    # Usage      : $info = IPlant::TreeRec::GeneFamilyInfo->new(
    #                  {   dbh                  => $dbh,
    #                      go_term_length_limit => $limit,
    #                      go_categories        => \@categories,
    #                  }
    #              );
    #
    # Purpose    : Creates and initializes a new object instance.
    #
    # Returns    : The new object instance.
    #
    # Parameters : dbh                  - the database handle.
    #              go_term_length_limit - the length limit for the GO term.
    #              go_categories        - the list of GO term categories.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $dbh                  = $args_ref->{dbh};
        my $go_term_length_limit = $args_ref->{go_term_length_limit};
        my $go_categories        = $args_ref->{go_categories};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Initialize the object properties.
        $dbh_of{ ident $self }                  = $dbh;
        $go_term_length_limit_of{ ident $self } = $go_term_length_limit;
        $go_categories_of{ ident $self }        = $go_categories;

        return $self;
    }

    ##########################################################################
    # Usage      : N/A
    #
    # Purpose    : Cleans up after an instance of this class has gone out of
    #              scope.
    #
    # Returns    : Nothing.
    #
    # Parameters : None.
    #
    # Throws     : No exceptions.
    sub DESTROY {
        my ($self) = @_;

        # Clean up.
        delete $dbh_of{ ident $self };
        delete $go_term_length_limit_of{ ident $self };
        delete $go_categories_of{ ident $self };

        return;
    }

    ##########################################################################
    # Usage      : $summary_ref = $info->get_summary( $family_name,
    #                  $species_tree_name );
    #
    # Purpose    : Obtains summary information for a gene family.
    #
    # Returns    : The summary information.
    #
    # Parameters : $family_name       - the gene family name.
    #              $species_tree_name - the gene family tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub get_summary {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the gene family, species tree and reconciliation.
        my $family = $dbh->resultset('Family')->for_name($family_name);
        my $species_tree
            = $dbh->resultset('SpeciesTree')->for_name($species_tree_name);
        my $rec_id = $self->_get_reconciliation_id( $species_tree_name,
            $family_name );

        # Get the protein tree identifier.
        my $protein_tree_id = $self->_protein_tree_id_for_family($family);

        # Obtain the tree counts.
        my $summary_ref = $self->_get_tree_counts(
            $family->id(), $species_tree->id(),
            $rec_id,       $protein_tree_id
        );

        # Obtain the first GO term.
        $summary_ref->{go_annotations}
            = $self->_get_representative_go_term($protein_tree_id);

        return $summary_ref;
    }

    ##########################################################################
    # Usage      : $details_ref = $info->get_details( $family_name,
    #                  $species_tree_name );
    #
    # Purpose    : Obtains detail information for a gene family.  Currently,
    #              the detail information is the same as the summary
    #              information except that the entire list of GO annotatins
    #              is included in the detail information.
    #
    # Returns    : The detail information.
    #
    # Parameters : $family_name       - the gene family name.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub get_details {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the gene family, species tree and reconciliation.
        my $family = $dbh->resultset('Family')->for_name($family_name);
        my $species_tree
            = $dbh->resultset('SpeciesTree')->for_name($species_tree_name);
        my $rec_id = $self->_get_reconciliation_id( $species_tree_name,
            $family_name );

        # Get the protein tree identifier.
        my $protein_tree_id = $self->_protein_tree_id_for_family($family);

        # Obtain the tree counts.
        my $details_ref = $self->_get_tree_counts(
            $family->id(), $species_tree->id(),
            $rec_id,       $protein_tree_id
        );

        # Obtain all of the GO terms.
        $details_ref->{go_annotations}
            = [ $self->_get_all_go_terms($protein_tree_id) ];

        return $details_ref;
    }

    ##########################################################################
    # Usage      : $rec_id = $info->_get_reconciliation_id(
    #                  $species_tree_name, $family_name );
    #
    # Purpose    : Obtains the reconciliation ID for the given species tree
    #              name and family name.
    #
    # Returns    : The reconciliation ID or undef if the reconciliation
    #              couldn't be found.
    #
    # Parameters : $species_tree_name - the name of the species tree.
    #              $family_name       - the name of the gene family.
    #
    # Throws     : No exceptions.
    sub _get_reconciliation_id {
        my ( $self, $species_tree_name, $family_name ) = @_;

        # Quit early if the required arguments weren't prvided.
        return if !defined $species_tree_name || !defined $family_name;

        # Get the reconciliation.
        my $dbh = $dbh_of{ ident $self };
        my $rec = eval {
            $dbh->resultset('Reconciliation')
                ->for_species_tree_and_family( $species_tree_name,
                $family_name );
        };
        return if !defined $rec;

        return $rec->id();
    }

    ##########################################################################
    # Usage      : $protein_tree_id = $info->_protein_tree_id_for_family(
    #                  $family );
    #
    # Purpose    : Gets the protein tree identifier for a gene family.
    #
    # Returns    : The protein tree identifier.
    #
    # Parameters : $family - the gene family to get the protein tree for.
    #
    # Throws     : No exceptions.
    sub _protein_tree_id_for_family {
        my ( $self, $family ) = @_;

        # Get the protein tree.
        my $protein_tree = $family->protein_tree();
        return if !defined $protein_tree;

        return $protein_tree->id();
    }

    ##########################################################################
    # Usage      : $term = $info->_get_representative_go_term(
    #                  $protein_tree_id );
    #
    # Purpose    : Retrieves the most common go associated with the protein
    #              tree with the given identifier for the first category in
    #              our category list that has GO terms.
    #
    # Returns    : The GO term.
    #
    # Parameters : $protein_tree_id - the protein tree identifier.
    #
    # Throws     : No exceptions.
    sub _get_representative_go_term {
        my ( $self, $protein_tree_id ) = @_;

        # Extract the GO term categories.
        my $go_categories_ref = $go_categories_of{ ident $self };

        # Fetch the most common GO term in the first category that has terms.
        my $go_term;
        CATEGORY:
        for my $category ( @{$go_categories_ref} ) {
            my $category_id = $self->_get_go_category_id($category);
            next CATEGORY if !defined $category_id;
            $go_term = $self->_get_go_term( $protein_tree_id, $category_id );
            last CATEGORY if defined $go_term;
        }

        return $go_term;
    }

    ##########################################################################
    # Usage      : $cvterm_id = $info->_get_go_category_id($category);
    #
    # Purpose    : Get the cvterm ID for the GO category with the given name.
    #
    # Returns    : The ID.
    #
    # Parameters : $category - the name of the GO category.
    #
    # Throws     : No exceptions.
    sub _get_go_category_id {
        my ( $self, $category ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the cvterm for the GO category.
        my $cvterm
            = $dbh->resultset('Cvterm')->find( { 'name' => $category } );
        return if !defined $cvterm;

        return $cvterm->id();
    }

    ##########################################################################
    # Usage      : $go_term = $info->_get_go_term( $protein_tree_id,
    #                  $category_id );
    #
    # Purpose    : Finds the most common GO term in the GO term category with
    #              the given identifier for the given protein tree ID.
    #
    # Returns    : The GO term or undef if no terms are found.
    #
    # Parameters : $protein_tree_id - the protein tree identifier.
    #              $category_id     - the GO term category identifier.
    #
    # Throws     : No exceptions.
    sub _get_go_term {
        my ( $self, $protein_tree_id, $category_id ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the list of GO terms.
        my @results = $dbh->resultset('GoTermsForFamilyAndCategory')
            ->search( {}, { 'bind' => [ $category_id, $protein_tree_id ] } );
        return if scalar @results == 0;

        return $results[0]->go_term();
    }

    ##########################################################################
    # Usage      : @go_terms = $info->_get_all_go_terms($protein_tree_id);
    #
    # Purpose    : Retrieves the GO terms for the given protein tree
    #              identifier.
    #
    # Returns    : The list of GO terms.
    #
    # Parameters : $protein_tree_id - the protein tree identifier.
    #
    # Throws     : No exceptions.
    sub _get_all_go_terms {
        my ( $self, $protein_tree_id )  = @_;

        # Get all of the GO term objects from the database.
        my $dbh     = $dbh_of{ ident $self };
        my @results = $dbh->resultset('GoTermsForFamily')
            ->search( {}, { 'bind' => [$protein_tree_id] } );

        # Extract the actual GO term from each of the GO term objects.
        return map { $_->go_term() } @results;
    }

    ##########################################################################
    # Usage      : $counts_ref = $info->_get_tree_counts( $family,
    #                  $species_tree, $rec, $protein_tree_id );
    #
    # Purpose    : Obtains the node counts for the tree.
    #
    # Returns    : A reference to the counts hash.
    #
    # Parameters : $family_id       - the gene family identifier.
    #              $species_tree_id - the species tree identifier.
    #              $rec_id          - the reconciliation identifier.
    #              $protein_tree_id - the protein tree identifier.
    #
    # Throws     : No exceptions.
    sub _get_tree_counts {
        my ( $self, $family_id, $species_tree_id, $rec_id, $protein_tree_id )
            = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get all of the counts.
        my %counts = (
            'gene_count'         => $self->_count_genes($family_id),
            'duplication_events' => $self->_count_duplications($rec_id),
            'speciation_events'  => $self->_count_speciations($rec_id),
            'species_count'      => $self->_count_species($species_tree_id),
            'go_term_count'      => $self->_count_go_terms($protein_tree_id),
        );

        return \%counts;
    }

    ##########################################################################
    # Usage      : $count = $info->_count_go_terms($protein_tree_id);
    #
    # Purpose    : Counts the number of GO terms associated with the given
    #              protein tree identifier.
    #
    # Returns    : The GO term count.
    #
    # Parameters : $protein_tree_id - the protein tree identifier.
    #
    # Throws     : No exceptions.
    sub _count_go_terms {
        my ( $self, $protein_tree_id ) = @_;
        return 0 if !defined $protein_tree_id;
        return scalar $self->_get_all_go_terms($protein_tree_id);
    }

    ##########################################################################
    # Usage      : $count = $info->_count_genes($family_id);
    #
    # Purpose    : Counts the number of genes in the given gene family ID.
    #
    # Returns    : The number of genes.
    #
    # Parameters : $family_id - the identifier of the gene family to examine.
    #
    # Throws     : No exceptions.
    sub _count_genes {
        my ( $self, $family_id ) = @_;

        # Don't count genes if no family ID was provided.
        return 0 if !defined $family_id;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the number of genes.
        my $count = $dbh->resultset('FamilyMember')
            ->count( { 'family_id' => $family_id } );

        return $count;
    }

    ##########################################################################
    # Usage      : $count = $info->_count_duplications($reconciliation_id);
    #
    # Purpose    : Counts the number of duplication events associated with the
    #              given reconciliation ID.
    #
    # Returns    : The number of duplication events.
    #
    # Parameters : $reconciliation_id - the ID of the reconciliation to
    #                                   examine.
    #
    # Throws     : No exceptions.
    sub _count_duplications {
        my ( $self, $reconciliation_id ) = @_;

        # Don't count duplications if no reconciliation ID was provided.
        return 0 if !defined $reconciliation_id;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the number of duplications.
        my @results = eval {
            $dbh->resultset('ReconciliationAttribute')
                ->get_values( $reconciliation_id, 'duplication' );
        };
        return scalar @results > 0 ? $results[0] : 0;
    }

    ##########################################################################
    # Usage      : $count = $info->_count_speciations($reconciliation_id);
    #
    # Purpose    : Counts the number of speciation events associated with the
    #              given reconciliation.
    #
    # Returns    : The number of speciation events.
    #
    # Parameters : $reconciliation_id - the ID of the reconciliation to
    #                                   examine.
    #
    # Throws     : No exceptions.
    sub _count_speciations {
        my ( $self, $reconciliation_id ) = @_;

        # Don't count speciations if no reconciliation ID was provided.
        return 0 if !defined $reconciliation_id;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the number of speciations.
        my @results = eval {
            $dbh->resultset('ReconciliationAttribute')
                ->get_values( $reconciliation_id, 'speciation' );
        };
        return scalar @results > 0 ? $results[0] : 0;
    }

    ##########################################################################
    # Usage      : $count = $info->_count_species($species_tree_id);
    #
    # Purpose    : Counts the number of species in the given species tree
    #              identifier.
    #
    # Returns    : The species count.
    #
    # Parameters : $species_tree_id - the species tree identifier.
    #
    # Throws     : No exceptions.
    sub _count_species {
        my ( $self, $species_tree_id ) = @_;

        # Don't count species if no species tree ID was provided.
        return 0 if !defined $species_tree_id;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the species tree count.
        my @results = $dbh->resultset('SpeciesCount')
            ->search( {}, { 'bind' => [ $species_tree_id ] } );
        return scalar @results > 0 ? $results[0]->species_count() : 0;
    }
}

1;
__END__
