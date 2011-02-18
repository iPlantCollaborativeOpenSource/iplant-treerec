package IPlant::TreeRec;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Bio::Tree::NodeNHX;
use Bio::TreeIO;
use Carp;
use Class::Std::Utils;
use Data::Dumper;
use English qw( -no_match_vars );
use IO::Scalar;
use IPlant::DB::TreeRec;
use IPlant::TreeRec::BlastArgs;
use IPlant::TreeRec::DuplicationEventFinder;
use IPlant::TreeRec::ProteinTreeNodeFinder;
use IPlant::TreeRec::ReconciliationLoader;
use IPlant::TreeRec::ReconciliationResolver;
use IPlant::TreeRec::TreeDataFormatter;
use IPlant::TreeRec::Utils qw(camel_case_keys);
use IPlant::TreeRec::X;
use List::MoreUtils qw(uniq);
use Time::HiRes qw(time);
use Readonly;

# The default default species tree.
Readonly my $DEFAULT_DEFAULT_SPECIES_TREE => 'bowers_rosids';

{
    my %dbh_of;
    my %gene_tree_loader_of;
    my %gene_family_info_of;
    my %file_retriever_of;
    my %blast_searcher_of;
    my %default_species_tree_of;
    my %gene_tree_events_of;
    my %go_cloud_generator_of;
    my %species_tree_events_of;

    ##########################################################################
    # Usage      : $treerec = IPlant::TreeRec->new(
    #                  {   dbh                  => $dbh,
    #                      gene_tree_loader     => $tree_loader,
    #                      gene_family_info     => $info,
    #                      file_retreiver       => $file_retriever,
    #                      blast_searcher       => $blast_searcher,
    #                      default_species_tree => $species_tree_name,
    #                      gene_tree_events     => $tree_decorations,
    #                      go_cloud_generator   => $go_cloud_generator,
    #                  }
    #              );
    #
    # Purpose    : Initializes a new object with the given database connection
    #              settings.
    #
    # Returns    : The new object.
    #
    # Parameters : dbh                   - the database handle.
    #              gene_tree_loader      - used to load gene trees.
    #              gene_family_info      - used to get gene family summaries.
    #              file_retriever        - used to retrieve data files.
    #              blast_searcher        - used to perform BLAST searches.
    #              default_species_tree  - the default species tree.
    #              gene_tree_events      - used to note events in gene trees.
    #              go_cloud_generator    - used to generate GO clouds.
    #
    # Throws     : IPlant::TreeRec::DatabaseException
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $dbh                  = $args_ref->{dbh};
        my $gene_tree_loader     = $args_ref->{gene_tree_loader};
        my $gene_family_info     = $args_ref->{gene_family_info};
        my $file_retriever       = $args_ref->{file_retriever};
        my $blast_searcher       = $args_ref->{blast_searcher};
        my $default_species_tree = $args_ref->{default_species_tree};
        my $gene_tree_events 	 = $args_ref->{gene_tree_events};
 		my $species_tree_events  = $args_ref->{species_tree_events};
        my $go_cloud_generator   = $args_ref->{go_cloud_generator};

        # Use the default default species tree if one wasn't provided.
        if ( !defined $default_species_tree ) {
            $default_species_tree = $DEFAULT_DEFAULT_SPECIES_TREE;
        }

        # Create the new object.
        my $self = bless anon_scalar, $class;

        # Initialize the properties.
        $dbh_of{ ident $self }                  = $dbh;
        $gene_tree_loader_of{ ident $self }     = $gene_tree_loader;
        $gene_family_info_of{ ident $self }     = $gene_family_info;
        $file_retriever_of{ ident $self }       = $file_retriever;
        $blast_searcher_of{ ident $self }       = $blast_searcher;
        $default_species_tree_of{ ident $self } = $default_species_tree;
        $gene_tree_events_of{ ident $self }     = $gene_tree_events;
        $go_cloud_generator_of{ ident $self }   = $go_cloud_generator;
		$species_tree_events_of{ ident $self }  = $species_tree_events;

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
        delete $default_species_tree_of{ ident $self };
        delete $gene_tree_events_of{ ident $self };
        delete $go_cloud_generator_of{ ident $self };
        delete $species_tree_events_of{ ident $self };

        return;
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->go_search( $search_string,
    #                  $species_tree_name );
    #
    # Purpose    : Performs a search for a GO term or a GO accession
    #              number.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $search_string     - the string to search for.
    #              $species_tree_name - the name of the speices tree.
    #
    # Throws     : No exceptions.
    sub general_go_search {
        my ( $self, $search_string, $species_tree_name ) = @_;
        my $results_ref;

        # Remove whitespaces from the beginning and end of search string
        # This will take care of minor copy and paste errors.
        $search_string =~ s/^\s+//;
        $search_string =~ s/\s+$//;

        # This is the case where users uses GO:#######
        if ( $search_string =~ m/GO\:(\d*)/xms ) {

            $search_string = $1;

            # Pad with zeros to catch cases where the user did not
            # enter the full GO value with leading zeros.
            $search_string = sprintf( "%07d", $search_string );

            $results_ref = $self->_do_gene_family_search( 'GoAccessionSearch',
                $search_string, $species_tree_name );
            return $results_ref;
        }

        # This is the case where users enter #####
        elsif ( $search_string =~ m/(^\d+)/xms ) {

            # This will only return the first complete digit if there is
            # a longer list of digits

            # Pad with zeros to catch cases where the user did not
            # enter the full GO value with leading zeros.
            $search_string = sprintf( "%07d", $search_string );
            $results_ref = $self->_do_gene_family_search( 'GoAccessionSearch',
                $search_string, $species_tree_name );
            return $results_ref;
        }

        # The default is to assume the string is a text search
        else {
            $results_ref = $self->_do_gene_family_search( 'GoSearch',
                "\%$search_string\%", $species_tree_name );
            return $results_ref;

        }

    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->go_search( $search_string,
    #                  $species_tree_name );
    #
    # Purpose    : Performs a GO search.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $search_string     - the string to search for.
    #              $species_tree_name - the name of the speices tree.
    #
    # Throws     : No exceptions.
    sub go_search {
        my ( $self, $search_string, $species_tree_name ) = @_;
        my $results_ref
            = $self->_do_gene_family_search( 'GoSearch', "\%$search_string\%",
            $species_tree_name );
        return $results_ref;
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->go_accession_search(
    #                  $search_string, $species_tree_name );
    #
    # Purpose    : Performs a search by GO accession.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $search_string     - the string to search for.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : No exceptions.
    sub go_accession_search {
        my ( $self, $search_string, $species_tree_name ) = @_;
        my $results_ref = $self->_do_gene_family_search( 'GoAccessionSearch',
            $search_string, $species_tree_name );
        return $results_ref;
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->gene_id_search( $search_string,
    #                  $species_tree_name );
    #
    # Purpose    : Performs a gene identifier search.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $search_string     - the string to search for.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : No exceptions.
    sub gene_id_search {
        my ( $self, $search_string, $species_tree_name ) = @_;
        return $self->_do_gene_family_search( 'GeneIdSearch', $search_string,
            $species_tree_name );
    }

    ##########################################################################
    # Usage      : $go_cloud = $treerec->generate_go_cloud($family_name);
    #
    # Purpose    : Generates the GO term cloud for the given gene family name.
    #
    # Returns    : The GO term cloud as an HTML fragment.
    #
    # Parameters : $family_name - the name of the gene family.
    #
    # Throws     : No exceptions.
    sub get_go_cloud {
        my ( $self, $family_name ) = @_;

        # Generate and return the GO cloud.
        my $go_cloud_generator = $go_cloud_generator_of{ ident $self };
        my $cloud = $go_cloud_generator->generate_go_cloud($family_name);

        return { cloud => $cloud };
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->get_gene_family_summary(
    #                  $family_name, $species_tree_name );
    #
    # Purpose    : Gets the summary information for the given gene family
    #              name.  The results of this method are returned as a single-
    #              element array reference in order to match the results of
    #              the search methods.
    #
    # Returns    : A reference to a list containing the single gene family
    #              summary or a reference to an empty list of the gene family
    #              doesn't exist.
    #
    # Parameters : $family_name       - the name of the gene family.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : No exceptions.
    sub get_gene_family_summary {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Fetch the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Use the default species tree if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Load the results.
        my @families = ( { name => $family_name } );
        eval {
            $self->_load_gene_family_summaries( \@families,
                $species_tree_name );
        };
        if ( my $e = IPlant::TreeRec::GeneFamilyNotFoundException->caught() )
        {
            @families = ();
        }

        return \@families;
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->get_gene_family_details(
    #                  $family_name, $species_tree_name );
    #
    # Purpose    : Retrieves the gene family details for the given gene family
    #              name.
    #
    # Returns    : Detailed information about the gene family.
    #
    # Parameters : $family_name       - the gene family name.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub get_gene_family_details {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Use the default species tree if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Fetch the tree loader and family info retreiver.
        my $info = $gene_family_info_of{ ident $self };

        # Load the detailed information for the gene family.
        my $details_ref
            = $info->get_details( $family_name, $species_tree_name );

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
    # Usage      : $results_ref = $treerec->get_gene_tree_events(
    #                  $family_name, $species_tree_name );
    #
    # Purpose    : Retrieves the evolutionary events on the given gene family
    #              name.
    #
    # Returns    : Events.
    #
    # Parameters : $family_name       - the gene family name.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    sub get_gene_tree_events {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Use the default species tree if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Fetch the tree loader and family info retreiver.
        my $info = $gene_tree_events_of{ ident $self };

        # Load the events information for the gene family.
        my $details_ref
            = $info->get_events( $family_name, $species_tree_name );
            

        # Formats for output
        $details_ref = $self->_format_gene_tree_events( $details_ref, 'd_and_s' );

        return camel_case_keys($details_ref);
    }

    ##########################################################################
    # Usage      : $text = $treerec->get_gene_tree_file($json);
    #
    # Purpose    : Gets the gene tree for the gene family with the given name.
    #
    # Returns    : The gene tree.
    #
    # Parameters : familyName       - the name of the gene family.
    #              speciesTreeName  - the name of the species tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::ReconciliationNotFoundException
    #              IPlant::TreeRec::IllegalArgumentException
    sub get_gene_tree_file {
        my ( $self, $json ) = @_;

        # Extract the arguments.
        my ( $family_name, $species_tree_name )
            = $self->_extract_tree_args( $json, 'familyName' );

        # Use the default species tree if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Fetch the tree loader.
        my $tree_loader = $gene_tree_loader_of{ ident $self };

        # Load the tree.
        my $tree = $tree_loader->load_gene_tree($family_name);

        # Format and return the tree.
        my $filename     = "${family_name}_genetree.nhx";
        my $content_type = "application/nhx";
        my $contents     = $self->_format_tree( $tree, 'NHX' );
        return $self->_build_file_result( $filename, $content_type,
            $contents );
    }

    ##########################################################################
    # Usage      : $data_ref = $treerec->get_gene_tree_data($json);
    #
    # Purpose    : Retrieves the gene tree for thge gene family with the given
    #              name as a Perl data structure.
    #
    # Returns    : The tree data.
    #
    # Parameters : familyName      - the name of the gene family.
    #              speciesTreeName - the name of the species tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::ReconciliationNotFoundException
    #              IPlant::TreeRec::IllegalArgumentException
    sub get_gene_tree_data {
        my ( $self, $json ) = @_;

        # Extract the arguments.
        my ( $family_name, $species_tree_name )
            = $self->_extract_tree_args( $json, 'familyName' );

        # Use the default species tree if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Get the objects we need.
        my $dbh         = $dbh_of{ ident $self };
        my $tree_loader = $gene_tree_loader_of{ ident $self };
        my $formatter   = IPlant::TreeRec::TreeDataFormatter->new();
        my $rec_loader  = IPlant::TreeRec::ReconciliationLoader->new($dbh);

        # Load the tree.
        my $tree = $tree_loader->load_gene_tree($family_name);

        # Load the reconciliation if we're supposed to.
        my $reconciliation;
        if ( defined $species_tree_name ) {
            $reconciliation
                = $rec_loader->load( $species_tree_name, $family_name );
        }
        
        #Load the gene tree decorations
        my$gene_tree_decorations=$self->get_gene_tree_events($family_name);


        # Format the result.
        my %result = ( 'gene-tree' => $formatter->format_tree($tree) );
        $result{'gene-tree'}->{'styleMap'}=$gene_tree_decorations;
      
        if ( defined $reconciliation ) {
            $result{'reconciliation'} = $reconciliation;
        }

        return \%result;
    }

    ##########################################################################
    # Usage      : $text = $treerec->get_species_tree_file($json);
    #
    # Purpose    : Retrieves the species tree in NHX format.
    #
    # Returns    : The species tree.
    #
    # Parameters : speciesTreeName - the name of the species tree.
    #              familyName      - the name of the related gene tree.
    #
    # Throws     : IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::IllegalArgumentException
    sub get_species_tree_file {
        my ( $self, $json ) = @_;

        # Extract the arguments.
        my ( $family_name, $species_tree_name )
            = $self->_extract_tree_args($json);

        # Use the default species tree if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Fetch the tree loader.
        my $tree_loader = $gene_tree_loader_of{ ident $self };

        # Load the tree.
        my $tree = $tree_loader->load_species_tree($species_tree_name);

        # Determine the file name.
        my $filename
            = defined $species_tree_name
            ? "${species_tree_name}_speciestree.nhx"
            : "species_tree.nhx";

        # Format and return the tree.
        my $content_type = "application/nhx";
        my $contents = $self->_format_tree( $tree, 'NHX' );
        return $self->_build_file_result( $filename, $content_type,
            $contents );
    }

    ##########################################################################
    # Usage      : $data_ref = $treerec->get_species_tree_data($json)
    #
    # Purpose    : Retrieves species tree data in NHX format.
    #
    # Returns    : The species tree data.
    #
    # Parameters : speciesTreeName - the name of the species tree.
    #              familyName      - the name of the related gene tree.
    #
    # Throws     : IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::IllegalArgumentException
    sub get_species_tree_data {
        my ( $self, $json ) = @_;
		

        
        # Extract the arguments.
        my ( $family_name, $species_tree_name )
            = $self->_extract_tree_args($json);

        # Use the default species tree if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Fetch the tree loader and create a tree formatter.
        my $tree_loader = $gene_tree_loader_of{ ident $self };
        my $formatter   = IPlant::TreeRec::TreeDataFormatter->new();

        # Load the tree.
        my$tree = $tree_loader->load_species_tree($species_tree_name);
        my%results = %{$formatter->format_tree($tree)};
        
        		
        #Load the species tree decorations
        $results{styleMap}->{branchDecorations}=$self->get_species_tree_events($family_name, $species_tree_name);
        

        #Returns the tree.
        return \%results;
    }
    
    ##########################################################################
    # Usage      : $data_ref = $treerec->get_species_tree_event(
    #			   $family_name, $species_tree_name)
    #
    # Purpose    : Retrieves duplication events along the species tree.
    #
    # Returns    : The duplication events.
    #
    # Parameters : speciesTreeName - the name of the species tree.
    #              familyName      - the name of the related gene tree.
    #			   If no family name is provided the duplications across 
    #			   all gene families are returned	
    #
    # Throws     : IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::IllegalArgumentException
    sub get_species_tree_events {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Use the default species tree if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }
        # Fetch the tree loader and family info retreiver.
        my $info = $species_tree_events_of{ ident $self };

		#The output file
        my $details_ref;

        # Load the events information for the gene family.
        
        if( !defined $family_name || $family_name eq $species_tree_name){
            $details_ref = $info->get_all_duplications($species_tree_name );
        }
        else{
        	$details_ref = $info->get_duplications( $family_name, $species_tree_name );
        }

		#Format for output
		$details_ref=$self->_format_species_tree_events($details_ref,'species_tree');

        return camel_case_keys($details_ref);

    }   
    
    ##########################################################################
    # Usage      : @families = $treerec->find_duplication_events($json);
    #
    # Purpose    : Retrieves the names of gene families with duplication
    #              events at a selected location in a species tree.
    #
    # Returns    : A reference to a hash containing the list of family names.
    #
    # Parameters : nodeId       - the identifier of the selected node or the
    #                             node that the selected edge leads into.
    #              edgeSelected - true if the edge leading into the node is
    #                             selected rather than the node itself.
    #
    # Throws     : IPlant::TreeRec::IllegalArgumentException
    sub find_duplication_events {
        my ( $self, $json ) = @_;

        # Extract the arguments.
        my $args_ref      = JSON->new->decode($json);
        my $node_id       = $args_ref->{'nodeId'};
        my $edge_selected = $args_ref->{'edgeSelected'};

        # Validate the arguments.
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $node_id || !defined $edge_selected;

        # Create a new duplication event finder.
        my $dbh    = $dbh_of{ ident $self };
        my $finder = IPlant::TreeRec::DuplicationEventFinder->new($dbh);

        # Get the species tree name.
        my $species_tree
            = $dbh->resultset('SpeciesTree')->for_node_id($node_id);
        my $species_tree_name = $species_tree->species_tree_name();

        # Find the gene families containing duplication events.
        my @families
            = $finder->find_duplication_events( $node_id, $edge_selected );

        # Extract the columns from each of the matching results.
        @families = map {
            { $_->get_columns() }
        } @families;
        $self->_load_gene_family_summaries( \@families, $species_tree_name );

        # Convert the hash keys to camel-case.
        @families = map { camel_case_keys($_) } @families;

        return { 'families' => \@families };
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
    # Usage      : $results_ref = $treerec->blast_search( $blast_args_json
    #                  $species_tree_name );
    #
    # Purpose    : Performs a BLAST search on the given BLAST arguments
    #              search.
    #
    # Returns    : Summaries of all of the matching gene families.
    #              Relevant Keys as:
    #               geneFamilyName
    #               length
    #               evalue
    #
    # Parameters : $blast_args_json   - a JSON string representing the search
    #                                   parameters.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : No exceptions.
    sub blast_search {
        my ( $self, $blast_args_json, $species_tree_name ) = @_;

        # Use the species tree name if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Prepare for the search.
        my $searcher = $blast_searcher_of{ ident $self };
        my $blast_args
            = IPlant::TreeRec::BlastArgs->from_json($blast_args_json);

        # Do the BLAST search
        my @blast_results = $searcher->search($blast_args);

        # Find the gene family name for each BLAST match
        @blast_results
            = $self->_blast_results_to_family_names(@blast_results);

        # Prune any results we don't want.
        my @results = $self->_prune_blast_results(@blast_results);

        # Load the gene family summary information.
        $self->_load_gene_family_summaries( \@results, $species_tree_name );

        # Convert the hash keys to camel-case.
        @results = map { camel_case_keys($_) } @results;

        return { 'families', \@results };

    }

    ##########################################################################
    # Usage      : @results = $treerec->_prune_blast_results(@all_results);
    #
    # Purpose    : Keeps only the best hit for each gene identifier.  The
    #              BLAST program output is sorted with the best hit at the
    #              top, so loading only the first result for each gene ID
    #              will do what we want.
    #
    # Returns    : The pruned list of BLAST results.
    #
    # Parameters : @all_results - the list of BLAST results.
    #
    # Throws     : No exceptions.
    sub _prune_blast_results {
        my ( $self, @all_results ) = @_;
        my ( %seen, @results );

        # Find the list of unique results.
        foreach my $result (@all_results) {
            push( @results, $result ) unless $seen{ $result->{'gene_id'} }++;
        }

        return @results;
    }

    ##########################################################################
    # Usage      : @names = $treerec->_blast_results_to_family_names(
    #                  @blast_results );
    #
    # Purpose    : For set of  BLAST results contained in an array of hashes,
    #              this determines the gene family membership for each result
    #              and adds
    #
    # Returns    : The updated array of blast results.
    #
    # Parameters : @blast_results - the list of BLAST results.
    #
    # Throws     : No exceptions.
    #
    # Comments   :
    #   TO SPEED THIS UP, WE COULD ADD THE FAMILY NAME TO THE
    #   BLAST HEADERS AND PARSE THE RESULT FROM THE HIT IN THE
    #   BLAST RESULT
    #   FOR EXAMPLE FASTA HEADERS FOR BLAST DATABASE AS
    #   >geneID|geneFamilyName
    sub _blast_results_to_family_names {
        my ( $self, @blast_results ) = @_;

        # Fetch the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Find the family name for each gene ID in the list.
        for my $blast_result (@blast_results) {
            my $gene_id = $blast_result->{'gene_id'};
            my $member  = $dbh->resultset('Member')
                ->find( { stable_id => $gene_id } );

           # If the expectation is that a gene can belong to muliptle families
           # then this would need to make gene_family_name an array
            if ( defined $member ) {
                for my $family ( $member->families() ) {
                    $blast_result->{'name'} = $family->stable_id();
                }
            }
        }

        return @blast_results;
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->resolve_reconciliations($json);
    #
    # Purpose    : Searches for reconciliation nodes matching the given search
    #              parameters.  The species tree name and family name are
    #              always required.  The species tree node and edge-selected
    #              flag are required to find gene tree nodes corresponding to
    #              a species tree node.  The gene tree node is required to
    #              find species tree nodes corresponding to a gene tree node.
    #
    # Returns    : A reference to an array of matching reconciliation node
    #              information.  Eadch element in the result array is a fully
    #              populated version of the search parameters hash.
    #
    # Parameters : speciesTreeName - the name of the species tree.
    #              familyName      - the name of the gene family.
    #              speciesTreeNode - the species tree node ID.
    #              geneTreeNode    - the gene tree node ID.
    #              edgeSelected    - true if the leading edge is selected.
    #
    # Throws     : IPlant::TreeRec::IllegalArgumentException
    #              IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::ReconciliationNotFoundException
    sub resolve_reconciliations {
        my ( $self, $json ) = @_;

        # Parse the JSON that was provided to us.
        my $search_params_ref = JSON->new()->decode($json);

        # Use the default species tree name of one wasn't provided.
        if ( !defined $search_params_ref->{speciesTreeName} ) {
            $search_params_ref->{speciesTreeName}
                = $default_species_tree_of{ ident $self };
        }

        # Create a new reconciliation resolver.
        my $dbh      = $dbh_of{ ident $self };
        my $resolver = IPlant::TreeRec::ReconciliationResolver->new($dbh);

        # Resolve the nodes.
        return $resolver->resolve($search_params_ref);
    }

    ##########################################################################
    # Usage      : $results_ref = $treerec->genes_for_species($json);
    #
    # Purpose    : Gets the list of gene tree nodes for the given gene family
    #              name and species tree node ID.
    #
    # Returns    : A reference to a hash containing a reference to a list of
    #              gene tree node IDs.
    #
    # Parameters : familyName      - the gene family name.
    #              speciesTreeNode - the species tree node ID.
    #
    # Throws     : IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::NodeNotFoundException
    sub genes_for_species {
        my ( $self, $json ) = @_;

        # Parse the JSON that was provided to us.
        my $search_params_ref = JSON->new()->decode($json);

        # Create a protein tree node finder.
        my $dbh    = $dbh_of{ ident $self };
        my $finder = IPlant::TreeRec::ProteinTreeNodeFinder->new($dbh);

        # Extract the search parameters.
        my $family_name          = $search_params_ref->{familyName};
        my $species_tree_node_id = $search_params_ref->{speciesTreeNode};

        # Get the list of gene tree node IDs.
        my @gene_tree_nodes
            = $finder->for_species( $family_name, $species_tree_node_id );
        
        return { geneTreeNodes => \@gene_tree_nodes };
    }

    ##########################################################################
    # Usage      : ( $family_name, $species_tree_name ) = $treerec
    #                  ->_extract_tree_args( $json, $required_arg );
    #
    # Purpose    : Extracts the arguments required to retrieve a tree from the
    #              database.  If the given required argument doesn't exist
    #              then an exception will be thrown.
    #
    # Returns    : The extracted arguments.
    #
    # Parameters : $json         - the JSON string.
    #              $required_arg - the name of the required argument.
    #
    # Throws     : IPlant::TreeRec::IllegalArgumentException
    sub _extract_tree_args {
        my ( $self, $json, $required_arg ) = @_;

        # Decode the JSON string.
        my $args_ref = JSON->new->decode($json);

        # Verify that we have the required argument.
        IPlant::TreeRec::IllegalArgumentException->throw()
            if defined $required_arg && !defined $args_ref->{$required_arg};

        # Extract and return the arguments.
        return @{$args_ref}{qw( familyName speciesTreeName )};
    }

    ##########################################################################
    # Usage      : $result_ref = $treerec->_build_file_result( $filename,
    #                  $content_type, $contents );
    #
    # Purpose    : Creates a result that represents the contents of a file
    #
    # Returns    : The result.
    #
    # Parameters : $filename     - the name of the file.
    #              $content_type - the MIME content type for the file.
    #              $contents     - the file contents.
    #
    # Throws     : No exceptions.
    sub _build_file_result {
        my ( $self, $filename, $content_type, $contents ) = @_;
        return {
            "filename"     => $filename,
            "content_type" => $content_type,
            "contents"     => $contents,
        };
    }

    ##########################################################################
    # Usage      : $formatted_tree = $treerec->_format_tree( $tree, $format );
    #
    # Purpose    : Produces a representation of the given tree in the given
    #              format.
    #
    # Returns    : The formatted representation of the tree.
    #
    # Parameters : $tree   - the tree being formatted.
    #              $format - the format of the text represenation of the tree.
    #
    # Throws     : No exceptions.
    sub _format_tree {
        my ( $self, $tree, $format ) = @_;

        # Initialize the result.
        my $result = '';

        # Format the tree.
        my $handle = IO::Scalar->new( \$result );
        my $treeio = Bio::TreeIO->new( -format => $format, -fh => $handle );
        $treeio->write_tree($tree);

        return $result;
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
    #                  $search_string, $species_tree_name );
    #
    # Purpose    : Performs a gene family search.
    #
    # Returns    : Information about the matching gene families.
    #
    # Parameters : $type              - the type of search to perform.
    #              $search_string     - the string to search for.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : No exceptions.
    sub _do_gene_family_search {
        my ( $self, $type, $search_string, $species_tree_name ) = @_;

        # Use the default species tree name if one wasn't provided.
        if ( !defined $species_tree_name ) {
            $species_tree_name = $default_species_tree_of{ ident $self };
        }

        # Perform the search.
        my $dbh     = $dbh_of{ ident $self };
        my @results = $dbh->resultset($type)
            ->search( {}, { 'bind' => ["$search_string"] } );

        # Extract the columns from each of the matching results.
        @results = map {
            { $_->get_columns() }
        } @results;
        $self->_load_gene_family_summaries( \@results, $species_tree_name );

        # Convert the hash keys to camel-case.
        @results = map { camel_case_keys($_) } @results;

        return { 'families' => \@results };
    }

    ##########################################################################
    # Usage      : $updated_results_ref
    #                  = $treerec->_load_gene_family_summaries( $results_ref,
    #                    $species_tree_name );
    #
    # Purpose    : Loads the gene family summary information from gene family
    #              search results.  The search results should be in the form
    #              of a list of hash references in which each element contains
    #              a member named, "family_name", that contains the stable
    #              identifier of the gene family.
    #
    # Returns    : A reference to the updated results hash.
    #
    # Parameters : $results_ref       - a reference to the list of results.
    #              $species_tree_name - the name of the species tree.
    #
    # Throws     : No exceptions.
    sub _load_gene_family_summaries {
        my ( $self, $results_ref, $species_tree_name ) = @_;

        # Fetch the tree loader and family info retreiver.
        my $info = $gene_family_info_of{ ident $self };

        # Load the summary for each of the matching gene families.
        for my $result_ref ( @{$results_ref} ) {
            my $family_name = $result_ref->{name};
            my $summary_ref
                = $info->get_summary( $family_name, $species_tree_name );
            $result_ref = { %{$result_ref}, %{$summary_ref} };
        }

        return $results_ref;
    }

    ##########################################################################
    # Usage      : $data = $treerec->_format_gene_tree_events( $events, $style );
    #
    # Purpose    : Generates the visual properties for the gene tree
    #
    # Returns    : The formatted representation of the visual object.
    #
    # Parameters : $style - name of the style for the data that needs to
    #                       be represented.
    # 			   $events  - the list of speciation and duplication events.
    #
    # Throws     : No exceptions.
    sub _format_gene_tree_events {
        my ( $self, $events, $style ) = @_;
        my $results = {
            styles            => $self->_retrieve_decorations($style),
            nodeStyleMappings => $events
        };
        return $results;

    }


    ##########################################################################
    # Usage      : $data = $treerec->_format_species_tree_events( $events, $style );
    #
    # Purpose    : Generates the visual properties for the species tree
    #
    # Returns    : The formatted representation of the visual object.
    #
    # Parameters : $style - name of the style for the data that needs to
    #                       be represented.
    # 			   $events  - the list of speciation and duplication events.
    #
    # Throws     : No exceptions.
	sub _format_species_tree_events{
		my ( $self, $events, $style ) = @_;
		my$stylemap=$self->_retrieve_decorations($style);
		my$results;
		for my$key (keys %{$events}){
#### BUGFIX			
#### TO MAKE THE DUPLICATION ON THE BRANCH TO NULL OCCUR ON THE BRANCH TO 2 (GRAPE)
			if(!$key || $key eq '00'){
				$results->{2}=$stylemap->{function}($events->{$key});
			}
			else{	
				$results->{$key}=$stylemap->{function}($events->{$key});
			}		
		}
		return $results;	
				
		
	}
	

    ##########################################################################
    # Usage      : $data = $treerec->_retrieve_decorations( $style );
    #
    # Purpose    : Produces a representation of the visual style
    #
    # Returns    : The visual styles of the tree.
    #
    # Parameters : $style - name of the style for the metadata that needs to
    #                       be represented.
    #
    # Throws     : No exceptions.
    sub _retrieve_decorations {
        my ( $self, $style ) = @_;
		#This part will be replaced by database calls
		#
		#
		my$deco={
			d_and_s =>  {
    		   		duplication => {
    		       		nodeStyle=> {
               				color => '#ff0000',
               				pointSize => 6,
               				nodeShape=> 'circle'
         				},
          	 			labelStyle => {
               				color => '#000000'
           				},
           				branchStyle => {
              				strokeColor => '#000000',
              				lineWidth => 1
           				},
           				glyphStyle => {
               				fillColor => '#99FF99',
               				strokeColor => '#19B319',
               				lineWidth => 1
           				}
       				},
       				speciation => {
    		       		nodeStyle=> {
               				color => '#0000ff',
               				pointSize => 6,
               				nodeShape=> 'square'
         				},
          	 			labelStyle => {
               				color => '#000000'
           				},
           				branchStyle => {
               				strokeColor => '#000000',
               				lineWidth => 1
           				},
           				glyphStyle => {
               				fillColor => '#99FF99',
               				strokeColor => '#19B319',
               				lineWidth => 1
           				}
          			}
       		},
       		species_tree => {
       			function => \&_species_tree			
       		}
			
   		};
   	sub _species_tree{
   		return "triangle";	
   	}
			
   	return $deco->{$style};
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
James Estill
Naim Matasci

