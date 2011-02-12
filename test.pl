#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';

use Carp;
use Data::Dumper;
use DBI;
use English qw(-no_match_vars);
use Exception::Class;
use IPlant::TreeRec;
use IPlant::TreeRec::BlastArgs;
use IPlant::TreeRec::BlastSearcher;
use IPlant::TreeRec::DatabaseTreeLoader;
use IPlant::TreeRec::FileRetriever;
use IPlant::TreeRec::FileTreeLoader;
use IPlant::TreeRec::GeneFamilyInfo;
use IPlant::TreeRec::GeneTreeEvents;
use JSON qw();
use Perl6::Slurp;

use constant PASSWORD_FILE => "$ENV{HOME}/mysql.tr_searcher";

local $Data::Dumper::Useqq = 1;

# Establish the database connection.
my $dsn      = "DBI:mysql:database=tree_reconciliation";
my $user     = "tr_searcher";
my $password = load_password();
my $dbh      = IPlant::DB::TreeRec->connect( $dsn, $user, $password );


# Create the tree loader.
#my $tree_loader = IPlant::TreeRec::FileTreeLoader->new(
#    {   data_dir           => '/home/dennis/treerec/clusters',
#        filename_extension => '_genetree.nhx',
#        tree_format        => 'nhx',
#    }
#);
my $tree_loader = IPlant::TreeRec::DatabaseTreeLoader->new($dbh);

# Create the gene family info.
my $gene_family_info = IPlant::TreeRec::GeneFamilyInfo->new(
    {   dbh                  => $dbh,
        go_term_length_limit => 30,
    }
);

# Create the file retriever.
my $file_retriever = IPlant::TreeRec::FileRetriever->new(
    { data_dir => '/home/dennis/treerec/clusters' } );

# Create the BLAST searcher.
my $blast_searcher = IPlant::TreeRec::BlastSearcher->new(
    {   executable_dir => '/usr/bin',
        database_dir   => '/home/dennis/treerec/blastdb',
    }
);

# Create the gene tree decorations
my $gene_tree_decorations = IPlant::TreeRec::GeneTreeEvents->new(
	{	  dbh                  => $dbh,		
	}
);


# Create the tree reconciliation object.
my $treerec = IPlant::TreeRec->new(
    {   dbh              => $dbh,
        gene_tree_loader => $tree_loader,
        gene_family_info => $gene_family_info,
        file_retriever   => $file_retriever,
        blast_searcher   => $blast_searcher,
        gene_tree_decorations =>$gene_tree_decorations,
    }
);


eval {
    # warn Dumper $treerec->go_search("miRNA binding");
    # warn Dumper $treerec->go_accession_search("0031124");
    # warn Dumper $treerec->gene_id_search("V01G0907");
#     warn Dumper $treerec->get_gene_family_summary("pg00921");
    warn Dumper $treerec->get_gene_tree_events("pg01321");
 #   warn Dumper $treerec->get_rec('bowers_rosids','pg00892');
#    warn Dumper $treerec->get_gene_family_summary("pg00921");
#     warn Dumper $treerec->get_gene_family_summary("pg00892");
    #warn Dumper $treerec->get_gene_family_details("pg00921");
    # warn Dumper get_gene_tree_file( $treerec, 'pg00892' );
    # warn Dumper get_gene_tree_file( $treerec, 'pg00892', 'bowers_rosids' );
    # warn Dumper get_species_tree_file( $treerec, 'bowers_rosids' );
    # warn Dumper get_species_tree_file( $treerec, 'bowers_rosids', 'pg00892' );
     warn Dumper get_gene_tree_data( $treerec, 'pg01321' );
    # warn Dumper get_gene_tree_data( $treerec, 'pg00892', 'bowers_rosids' );
    # warn Dumper get_species_tree_data( $treerec, 'bowers_rosids' );
    # warn Dumper get_species_tree_data( $treerec, 'bowers_rosids', 'pg00892' );

    # warn Dumper $treerec->resolve_reconciliations(
    #     JSON->new()->encode(
    #         {   'speciesTreeName' => 'bowers_rosids',
    #             'familyName'      => 'pg00892',
    #             'speciesTreeNode' => 8,
    #             'edgeSelected'    => 0,
    #         }
    #     )
    # );
    # warn Dumper $treerec->resolve_reconciliations(
    #     JSON->new()->encode(
    #         {   'speciesTreeName' => 'bowers_rosids',
    #             'familyName'      => 'pg00892',
    #             'speciesTreeNode' => 8,
    #             'edgeSelected'    => 1,
    #         }
    #     )
    # );
    # warn Dumper $treerec->resolve_reconciliations(
    #     JSON->new()->encode(
    #         {   'speciesTreeName' => 'bowers_rosids',
    #             'familyName'      => 'pg00892',
    #             'geneTreeNode'    => 8,
    #         }
    #     )
    # );

    # for my $type ( $file_retriever->get_file_types() ) {
    #     warn Dumper $treerec->get_file( $type, 'pg00892' );
    # }

    # warn Dumper blast_search( $treerec, 'nucleotide', 'dna_query.fa' );
    # warn Dumper blast_search( $treerec, 'protein', 'protein_query.fa' );
 #   warn Dumper blast_search( $treerec, 'protein', 'protein_query_pg00921.fa' );
    # warn Dumper find_duplication_events( $treerec, 10, 1 );
    # warn Dumper find_duplication_events( $treerec, 10, 1 );
};
if ( my $e = Exception::Class->caught() ) {
    warn "Exception: $e";
    if ( ref $e ) {
        warn $e->trace()->as_string();
    }
}

exit;

##########################################################################
# Usage      : $dbh = connect( $dsn, $user, $password );
#
# Purpose    : Establishes the database connection.
#
# Returns    : The database handle.
#
# Parameters : $dsn      - the data source name.
#              $user     - the username used to access the database.
#              $password - the password used to access the database.
#
# Throws     : IPlant::TreeRec::DatabaseException
sub connect {
    my ( $dsn, $user, $password ) = @_;

    # Establish the database connection.
    my $dbh = IPlant::DB::TreeRec->connect( $dsn, $user, $password );
    IPlant::TreeRec::DatabaseException->throw( error => DBI::errstr )
        if !defined $dbh;

    return $dbh;
}

##########################################################################
# Usage      : $password = load_password();
#
# Purpose    : Loads the password from the password file.
#
# Returns    : The password.
#
# Parameters : None.
#
# Throws     : "unable to open $file for input: $reason"
#              "unable to close $file: $reason"
sub load_password {
    my $file = PASSWORD_FILE;

    # Open the file.
    open my $in, '<', $file
        or croak "unable to open $file for input: $ERRNO";

    # Load the contents of the file.
    my $password = do { local $\; <$in> };

    # Close the file.
    close $in
        or croak "unable to close $file: $ERRNO";

    return $password;
}

##########################################################################
# Usage      : $results_ref = blast_search( $treerec, $type, $file );
#
# Purpose    : Performs a BLAST search.
#
# Returns    : The results of the BLAST search.
#
# Parameters : $treerec - an instance of IPlant::TreeRec.
#              $type    - the type of sequence (nucleotide or protein).
#              $file    - the name of the file containing the sequence.
#
# Throws     : No exceptions.
sub blast_search {
    my ( $treerec, $type, $file ) = @_;

    # Build the BLAST arguments JSON.
    my $blast_args_json = JSON->new()->encode(
        {   sequenceType => $type,
            sequence     => scalar slurp $file,
        }
    );

    #Perform the search.
    return $treerec->blast_search($blast_args_json);
}

##########################################################################
# Usage      : $results_ref = find_duplication_events( $treerec,
#                  $node_id, $edge_selected );
#
# Purpose    : Finds gene family names with duplication events in a
#              specific point in a species tree.
#
# Returns    : A reference to a list of gene family names.
#
# Parameters : $treerec       - an instance of IPlant::TreeRec.
#              $node_id       - the node identifier.
#              $edge_selected - true if the edge is selected.
#
# Throws     : No exceptions.
sub find_duplication_events {
    my ( $treerec, $node_id, $edge_selected ) = @_;

    # Build the arguments JSON.
    my $edge_selected_json = $edge_selected ? JSON::true : JSON::false;
    my $json = JSON->new()->encode(
        {   nodeId       => $node_id,
            edgeSelected => $edge_selected_json,
        }
    );

    # Perform the search.
    return $treerec->find_duplication_events($json);
}

##########################################################################
# Usage      : $results_ref = get_gene_tree_data( $treerec, $family_name,
#                  $species_tree_name );
#
# Purpose    : Gets the gene tree data for the given gene family name
#              and, optionally, for the given species tree name.
#
# Returns    : A reference to the gene tree data.
#
# Parameters : $treerec           - an instance of IPlant::TreeRec.
#              $family_name       - the gene family name.
#              $species_tree_name - the name of the species tree.
#
# Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
#              IPlant::TreeRec::TreeNotFoundException
#              IPlant::TreeRec::ReconciliationNotFoundException
#              IPlant::TreeRec::IllegalArgumentException
sub get_gene_tree_data {
    my ( $treerec, $family_name, $species_tree_name ) = @_;
    my $json = build_tree_args( $family_name, $species_tree_name );
    return $treerec->get_gene_tree_data($json);
}


##########################################################################
# Usage      : $results_ref = get_gene_tree_decorations( $treerec, $family_name,
#                  $species_tree_name );
#
# Purpose    : Gets the gene tree decorations for the given gene family name
#              and, optionally, for the given species tree name.
#
# Returns    : A reference to the gene tree data.
#
# Parameters : $treerec           - an instance of IPlant::TreeRec.
#              $family_name       - the gene family name.
#              $species_tree_name - the name of the species tree.
#
# Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
#              IPlant::TreeRec::TreeNotFoundException
#              IPlant::TreeRec::ReconciliationNotFoundException
#              IPlant::TreeRec::IllegalArgumentException
#sub get_gene_tree_decorations {
#    my ( $treerec, $family_name, $species_tree_name ) = @_;
#    my $json = build_tree_args( $family_name, $species_tree_name );
#    return $treerec->get_gene_tree_decorations($json);
#}

##########################################################################
# Usage      : $results_ref = get_gene_tree_file( $treerec, $family_name,
#                  $species_tree_name );
#
# Purpose    : Gets the gene tree file information for the given gene
#              family name and, optionally, for the given species tree
#              name.
#
# Returns    : A reference to the gene tree data.
#
# Parameters : $treerec           - an instance of IPlant::TreeRec.
#              $family_name       - the gene family name.
#              $species_tree_name - the name of the species tree.
#
# Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
#              IPlant::TreeRec::TreeNotFoundException
#              IPlant::TreeRec::ReconciliationNotFoundException
#              IPlant::TreeRec::IllegalArgumentException
sub get_gene_tree_file {
    my ( $treerec, $family_name, $species_tree_name ) = @_;
    my $json = build_tree_args( $family_name, $species_tree_name );
    return $treerec->get_gene_tree_file($json);
}

##########################################################################
# Usage      : $results_ref = get_species_tree_data( $treerec,
#                  $species_tree_name, $family_name );
#
# Purpose    : Gets the species tree data for the given species tree name
#              and, optionally, for the given gene family name.
#
# Returns    : A reference to the gene tree data.
#
# Parameters : $treerec           - an instance of IPlant::TreeRec.
#              $species_tree_name - the name of the species tree.
#              $family_name       - the gene family name.
#
# Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
#              IPlant::TreeRec::TreeNotFoundException
#              IPlant::TreeRec::ReconciliationNotFoundException
#              IPlant::TreeRec::IllegalArgumentException
sub get_species_tree_data {
    my ( $treerec, $species_tree_name, $family_name ) = @_;
    my $json = build_tree_args( $family_name, $species_tree_name );
    return $treerec->get_species_tree_data($json);
}

##########################################################################
# Usage      : $results_ref = get_gene_tree_file( $treerec,
#                  $species_tree_name, $family_name );
#
# Purpose    : Gets the species tree file information for the given
#              species tree name and, optionally, for the given species
#              tree name.
#
# Returns    : A reference to the gene tree data.
#
# Parameters : $treerec           - an instance of IPlant::TreeRec.
#              $family_name       - the gene family name.
#              $species_tree_name - the name of the species tree.
#
# Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
#              IPlant::TreeRec::TreeNotFoundException
#              IPlant::TreeRec::ReconciliationNotFoundException
#              IPlant::TreeRec::IllegalArgumentException
sub get_species_tree_file {
    my ( $treerec, $species_tree_name, $family_name ) = @_;
    my $json = build_tree_args( $family_name, $species_tree_name );
    return $treerec->get_species_tree_file($json);
}

##########################################################################
# Usage      : $json = build_tree_args( $family_name,
#                  $species_tree_name );
#
# Purpose    : Builds the JSON string to be passed to the methods used
#              to get tree data and files.
#
# Returns    : The JSON string.
#
# Parameters : $family_name       - the name of the gene family.
#              $species_tree_name - the name of the species tree.
#
# Throws     : No exceptions.
sub build_tree_args {
    my ( $family_name, $species_tree_name ) = @_;

    # Build the arguments JSON.
    my $args_ref = { familyName => $family_name };
    if ( defined $species_tree_name ) {
        $args_ref->{speciesTreeName} = $species_tree_name;
    }
    my $json = JSON->new()->encode($args_ref);

    return $json;
}
