package IPlant::TreeRec;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Bio::Tree::NodeNHX;
use Bio::TreeIO;
use Carp;
use Class::Std::Utils;
use Data::Dumper;
use English qw( -no_match_vars );
use IPlant::DB::TreeRec;
use IPlant::TreeRec::BlastArgs;
use IPlant::TreeRec::Utils qw(camel_case_keys);
use IPlant::TreeRec::X;
use List::MoreUtils qw(uniq);
use Time::HiRes qw(time);

{
    my %dbh_of;
    my %gene_tree_loader_of;
    my %gene_family_info_of;
    my %file_retriever_of;
    my %blast_searcher_of;

    ##########################################################################
    # Usage      : $treerec = IPlant::TreeRec->new(
    #                  {   dbh              => $dbh,
    #                      gene_tree_loader => $tree_loader,
    #                      gene_family_info => $info,
    #                      file_retreiver   => $file_retriever,
    #                      blast_searcher   => $blast_searcher,
    #                  }
    #              );
    #
    # Purpose    : Initializes a new object with the given database connection
    #              settings.
    #
    # Returns    : The new object.
    #
    # Parameters : dbh              - the database handle.
    #              gene_tree_loader - used to load gene trees.
    #              gene_family_info - used to get gene family summaries.
    #              file_retriever   - used to retrieve data files.
    #              blast_searcher   - used to perform BLAST searches.
    #
    # Throws     : IPlant::TreeRec::DatabaseException
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $dbh              = $args_ref->{dbh};
        my $gene_tree_loader = $args_ref->{gene_tree_loader};
        my $gene_family_info = $args_ref->{gene_family_info};
        my $file_retriever   = $args_ref->{file_retriever};
        my $blast_searcher   = $args_ref->{blast_searcher};

        # Create the new object.
        my $self = bless anon_scalar, $class;

        # Initialize the properties.
        $dbh_of{ ident $self }              = $dbh;
        $gene_tree_loader_of{ ident $self } = $gene_tree_loader;
        $gene_family_info_of{ ident $self } = $gene_family_info;
        $file_retriever_of{ ident $self }   = $file_retriever;
        $blast_searcher_of{ ident $self }   = $blast_searcher;

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
        delete $gene_tree_loader_of{ ident $self };
        delete $gene_family_info_of{ ident $self };
        delete $file_retriever_of{ ident $self };
        delete $blast_searcher_of{ ident $self };

        return;
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->go_search($search_string);
    #
    # Purpose    : Performs a GO search.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $search_string - the string to search for.
    #
    # Throws     : No exceptions.
    sub go_search {
        my ( $self, $search_string ) = @_;
        my $results_ref = $self->_do_gene_family_search( 'GoSearch',
            "\%$search_string\%" );
        return $results_ref;
    }

    ##########################################################################
    # Usage      : $results_ref
    #                  = $treerec->go_accession_search($search_string);
    #
    # Purpose    : Performs a search by GO accession.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $search_string - the string to search for.
    #
    # Throws     : No exceptions.
    sub go_accession_search {
        my ( $self, $search_string ) = @_;
        my $results_ref = $self->_do_gene_family_search( 'GoAccessionSearch',
            $search_string );
        return $results_ref;
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->gene_id_search($search_string);
    #
    # Purpose    : Performs a gene identifier search.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $search_string - the string to search for.
    #
    # Throws     : No exceptions.
    sub gene_id_search {
        my ( $self, $search_string ) = @_;
        return $self->_do_gene_family_search( 'GeneIdSearch',
            $search_string );
    }

    ##########################################################################
    # Usage      : $results_ref
    #                  = $treerec->get_gene_family_details($family_name);
    #
    # Purpose    : Retrieves the gene family details for the given gene family
    #              name.
    #
    # Returns    : Detailed information about the gene family.
    #
    # Parameters : $family_name - the gene family name.
    #
    # Throws     : No exceptions.
    sub get_gene_family_details {
        my ( $self, $family_name ) = @_;

        # Fetch the tree loader and family info retreiver.
        my $tree_loader = $gene_tree_loader_of{ ident $self };
        my $info        = $gene_family_info_of{ ident $self };

        # Load the detailed information for the gene family.
        my $tree = $tree_loader->load_gene_tree($family_name);
        my $details_ref = $info->get_details( $family_name, $tree );

        # Fetch the list of URL suffixes for file retrieval.
        my $file_retriever = $file_retriever_of{ ident $self };
        my $suffixes_ref   = $file_retriever->get_url_suffixes($family_name);

        # Add the gene family details URL suffix.
        $suffixes_ref->{getGeneFamilyDetails} = {
            relativeUrl => 'get/gene-family-details',
            fileFormat  => 'TEXT',
        };
        $details_ref->{relative_urls} = $suffixes_ref;

        return camel_case_keys($details_ref);
    }

    ##########################################################################
    # Usage      : $file_info_ref = $treerec->get_file( $type, $prefix );
    #
    # Purpose    : Retrieves the file of the given type, optionally with the
    #              given filename prefix.
    #
    # Returns    : Information about the file in the form of a hash reference
    #              containing the file name, content type and contents.
    #
    # Parameters : $type   - the type of file being retrieved.
    #              $prefix - the filename prefix.
    #
    # Throws     : No exceptions.
    sub get_file {
        my ( $self, $type, $prefix ) = @_;

        # Fetch the file retriever.
        my $retriever = $file_retriever_of{ ident $self };

        # Load the file information.
        return $retriever->load_file( $type, $prefix );
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->blast_search($blast_args_json);
    #
    # Purpose    : Performs a BLAST search on the given BLAST search
    #              arguments.
    #
    # Returns    : Summaries of all of the matching gene families.
    #
    # Parameters : $blast_args_json - a JSON string representing the search
    #                                 parameters.
    #
    # Throws     : No exceptions.
    sub blast_search {
        my ( $self, $blast_args_json ) = @_;

        # Prepare for the search.
        my $searcher = $blast_searcher_of{ ident $self };
        my $blast_args
            = IPlant::TreeRec::BlastArgs->from_json($blast_args_json);

        # Get the list of matching gene identifiers.
        my @gene_ids = $searcher->search($blast_args);

        # Get the summary information for each matching gene ID.
        my @results = map { { name => $_ } }
            $self->_gene_ids_to_family_names(@gene_ids);
        $self->_load_gene_family_summaries( \@results );

        # Convert the hash keys to camel-case.
        @results = map { camel_case_keys($_) } @results;

        return { 'families', \@results };
    }

    ##########################################################################
    # Usage      : @names = $treerec->_gene_ids_to_family_names(@gene_ids);
    #
    # Purpose    : Gets the list of unique family names for the given list of
    #              gene identifiers.
    #
    # Returns    : The list of family names.
    #
    # Parameters : @gene_ids - the list of gene identifiers.
    #
    # Throws     : No exceptions.
    sub _gene_ids_to_family_names {
        my ( $self, @gene_ids ) = @_;

        # Fetch the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Find the family name for each gene ID in the list.
        my @family_names;
        for my $gene_id (@gene_ids) {
            $gene_id =~ s/ _ [^_]+ \z //gxms;
            my $member = $dbh->resultset('Member')
                ->find( { stable_id => $gene_id } );
            if ( defined $member ) {
                for my $family ( $member->families() ) {
                    push @family_names, $family->stable_id();
                }
            }
        }

        return uniq @family_names;
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->_do_gene_family_search( $type,
    #                  $search_string );
    #
    # Purpose    : Performs a gene family search.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $type          - the type of search to perform.
    #              $search_string - the string to search for.
    #
    # Throws     : No exceptions.
    sub _do_gene_family_search {
        my ( $self, $type, $search_string ) = @_;

        # Perform the search.
        my $dbh     = $dbh_of{ ident $self };
        my @results = $dbh->resultset($type)
            ->search( {}, { 'bind' => ["$search_string"] } );

        # Extract the columns from each of the matching results.
        @results = map {
            { $_->get_columns() }
        } @results;
        $self->_load_gene_family_summaries( \@results );

        # Convert the hash keys to camel-case.
        @results = map { camel_case_keys($_) } @results;

        return { 'families' => \@results };
    }

    ##########################################################################
    # Usage      : $updated_results_ref
    #                  = $treerec->_load_gene_family_summaries($results_ref);
    #
    # Purpose    : Loads the gene family summary information from gene family
    #              search results.  The search results should be in the form
    #              of a list of hash references in which each element contains
    #              a member named, "family_name", that contains the stable
    #              identifier of the gene family.
    #
    # Returns    : A reference to the updated results hash.
    #
    # Parameters : $results_ref - a reference to the list of results.
    #
    # Throws     : No exceptions.
    sub _load_gene_family_summaries {
        my ( $self, $results_ref ) = @_;

        # Fetch the tree loader and family info retreiver.
        my $tree_loader = $gene_tree_loader_of{ ident $self };
        my $info        = $gene_family_info_of{ ident $self };

        # Load the summary for each of the matching gene families.
        for my $result_ref ( @{$results_ref} ) {
            my $family_name = $result_ref->{name};
            my $tree        = $tree_loader->load_gene_tree($family_name);
            my $summary_ref = $info->get_summary( $family_name, $tree );
            $result_ref = { %{$result_ref}, %{$summary_ref} };
        }

        return $results_ref;
    }
}

1;
__END__

=head1 NAME

IPlant::TreeRec - perl extension for accessing reconciled gene trees.

=head1 VERSION

This documentation refers to IPlant::TreeRec version 0.0.1.

=head1 SYNOPSIS

    use IPlant::TreeRec;

    # Create a new object.
    $treerec = IPlant::TreeRec->new(
        {   dbh              => $dbh,
            gene_tree_loader => $tree_loader,
            gene_family_info => $info,
            file_retreiver   => $file_retriever,
            blast_searcher   => $blast_searcher,
        }
    );

    # Perform a GO term search.
    $results_ref = $treerec->go_search($search_term);

    # Perform a GO accession search.
    $results_ref = $treerec->go_accession_search($accession);

    # Perform a BLAST search.
    $results_ref = $treerec->blast_search($blast_args);

    # Perform a gene identifier search.
    $results_ref = $treerec->gene_id_search($gene_id);

    # Get information about a gene family.
    $details_ref = $treerec->gene_family_details($family_name);

    # Get file metadata and contents.
    $file_info = $treerec->get_file( $file_type, $file_name_prefix );

=head1 DESCRIPTION

Provides high-level functions for obtaining information about reconciled
gene families.

=head1 AUTHOR

Dennis Roberts (dennis@iplantcollaborative.org)

