package IPlant::TreeRec::GeneFamilyInfo;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );
use Memoize;
memoize( '_count_genes' );
memoize( '_count_duplications' );
memoize( '_count_speciations' );
memoize( '_count_species' );

{
    my %dbh_of;
    my %go_term_length_limit_of;

    ##########################################################################
    # Usage      : $info = IPlant::TreeRec::GeneFamilyInfo->new(
    #                  {   dbh                  => $dbh,
    #                      go_term_length_limit => $limit,
    #                  }
    #              );
    #
    # Purpose    : Creates and initializes a new object instance.
    #
    # Returns    : The new object instance.
    #
    # Parameters : dbh                  - the database handle.
    #              go_term_length_limit - the length limit for the GO term.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $dbh                  = $args_ref->{dbh};
        my $go_term_length_limit = $args_ref->{go_term_length_limit};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Initialize the object properties.
        $dbh_of{ ident $self }                  = $dbh;
        $go_term_length_limit_of{ ident $self } = $go_term_length_limit;

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
    # Throws     : No exceptions.
    sub get_summary {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Obtain the tree counts.
        my $summary_ref
            = $self->_get_tree_counts( $family_name, $species_tree_name );

        # Obtain the first GO term.
        $summary_ref->{go_annotations} = $self->_get_go_term($family_name);

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
    # Throws     : No exceptions.
    sub get_details {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Obtain the tree counts.
        my $details_ref
            = $self->_get_tree_counts( $family_name, $species_tree_name );

        # Obtain all of the GO terms.
        $details_ref->{go_annotations}
            = [ $self->_get_all_go_terms($family_name) ];

        return $details_ref;
    }

    ##########################################################################
    # Usage      : $truncated_go_term
    #                  = $info->_get_go_term($family_name);
    #
    # Purpose    : Retrieves the first GO term for the given gene family and
    #              truncates it if there's a length limit.
    #
    # Returns    : The truncated GO term.
    #
    # Parameters : $family_name - the name of the gene family.
    #
    # Throws     : No exceptions.
    sub _get_go_term {
        my ( $self, $family_name ) = @_;

        # Fetch the first GO term.
        my @go_terms = $self->_get_all_go_terms($family_name);
        my $go_term = scalar @go_terms > 0 ? $go_terms[0] : "";

        # Add an ellipsis for long or multiple terms.
        my $length_limit = $go_term_length_limit_of{ ident $self };
        if ( defined $length_limit ) {
            if ( length $go_term > $length_limit || scalar @go_terms > 0 ) {
                $go_term = substr( $go_term, 0, $length_limit - 3 ) . "...";
            }
        }

        return $go_term;
    }

    ##########################################################################
    # Usage      : @go_terms = $info->_get_all_go_terms($family_name);
    #
    # Purpose    : Retrieves the GO terms for the given gene family.
    #
    # Returns    : The list of GO terms.
    #
    # Parameters : $family_name - the name of the gene family.
    #
    # Throws     : No exceptions.
    sub _get_all_go_terms {
        my ( $self, $family_name )  = @_;

        # Get all of the GO term objects from the database.
        my $dbh     = $dbh_of{ ident $self };
        my @results = $dbh->resultset('GoTermsForFamily')
            ->search( {}, { 'bind' => [$family_name] } );

        # Extract the actual GO term from each of the GO term objects.
        return map { $_->go_term() } @results;
    }

    ##########################################################################
    # Usage      : $counts_ref = $info->_get_tree_counts( $family_name,
    #                  $species_tree_name );
    #
    # Purpose    : Obtains the node counts for the tree.
    #
    # Returns    : A reference to the counts hash.
    #
    # Parameters : $family_name       - the name of the gene family.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : No exceptions.
    sub _get_tree_counts {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the gene family, species tree and reconciliation.
        my $family = $dbh->resultset('Family')->for_name($family_name);
        my $species_tree
            = $dbh->resultset('SpeciesTree')->for_name($species_tree_name);
        my $rec = $dbh->resultset('Reconciliation')
            ->for_species_tree_and_family( $species_tree_name, $family_name );

        # Get all of the counts.
        my %counts = (
            'gene_count'         => $self->_count_genes($family),
            'duplication_events' => $self->_count_duplications($rec),
            'speciation_events'  => $self->_count_speciations($rec),
            'species_count'      => $self->_count_species($species_tree),
        );

        return \%counts;
    }

    ##########################################################################
    # Usage      : $count = $info->_count_genes($family);
    #
    # Purpose    : Counts the number of genes in the given gene family.
    #
    # Returns    : The number of genes.
    #
    # Parameters : $family - the gene family to examine.
    #
    # Throws     : No exceptions.
    sub _count_genes {
        my ( $self, $family ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the number of genes.
        my $count = $dbh->resultset('FamilyMember')
            ->count( { 'family_id' => $family->id() } );

        return $count;
    }

    ##########################################################################
    # Usage      : $count = $info->_count_duplications($reconciliation);
    #
    # Purpose    : Counts the number of duplication events associated with the
    #              given reconciliation.
    #
    # Returns    : The number of duplication events.
    #
    # Parameters : $reconciliation - the reconciliation to examine.
    #
    # Throws     : No exceptions.
    sub _count_duplications {
        my ( $self, $reconciliation ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the number of duplications.
        my @results = eval { $dbh->resultset('DuplicationCount')
            ->search( {}, { 'bind' => [ $reconciliation->id() ] } ) };
        warn $EVAL_ERROR if $EVAL_ERROR;
        return scalar @results > 0 ? $results[0]->duplication_count() : 0;
    }

    ##########################################################################
    # Usage      : $count = $info->_count_speciations($reconciliation);
    #
    # Purpose    : Counts the number of speciation events associated with the
    #              given reconciliation.
    #
    # Returns    : The number of speciation events.
    #
    # Parameters : $reconciliation - the reconciliation to examine.
    #
    # Throws     : No exceptions.
    sub _count_speciations {
        my ( $self, $reconciliation ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the number of speciations.
        my @results = eval { $dbh->resultset('SpeciationCount')
            ->search( {}, { 'bind' => [ $reconciliation->id() ] } ) };
        warn $EVAL_ERROR if $EVAL_ERROR;
        return scalar @results > 0 ? $results[0]->speciation_count() : 0;
    }

    ##########################################################################
    # Usage      : $count = $info->_count_species($species_tree);
    #
    # Purpose    : Counts the number of species in the given species tree.
    #
    # Returns    : The species count.
    #
    # Parameters : $species_tree - the species tree.
    #
    # Throws     : No exceptions.
    sub _count_species {
        my ( $self, $species_tree ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the species tree count.
        my @results = $dbh->resultset('SpeciesCount')
            ->search( {}, { 'bind' => [ $species_tree->id() ] } );
        return scalar @results > 0 ? $results[0]->species_count() : 0;
    }
}

1;
__END__
