#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           |
# tr_import_reconciled_tree.pl                              |
#                                                           |
#-----------------------------------------------------------+
#                                                           |
# CONTACT: JamesEstill_at_gmail.com                         |
# STARTED: 09/15/2010                                       |
# UPDATED: 03/29/2011                                       |
#                                                           |
# DESCRIPTION:                                              | 
#  Import gene trees and reconcilations into the database   |
#  from PRIME format input files.                           |
#                                                           |
# LICENSE:                                                  |
#  Simplified BSD License                                   |
#  http://tinyurl.com/iplant-tr-license                     |
#                                                           |
#-----------------------------------------------------------+
#
# TO DO:
# - USE TRANSACTIONS throughout
# - Fix loading of data to look up values from database and not 
#   use predetermined integers. For reconciled tree_id mapping
#   that can use a translation input file to map from the 
#   id in the reconciliation to the id in the database.

# THIS WILL CURRENTLY LOAD THE GENE TREE FROM THIS RECONCILED
# TREE, LOAD THIS TO THE DATABASE, AND THEN MAP THIS RECONCILIATION
# TO THE NODES AND EDGES OF THE SPECIES TREE THAT IT MAPS TO
#
# TEST USE:
# ./tr_import_reconciled_tree.pl -i sandbox/pg17890_reconciled.nhx --format prime -s bowers_rosids
#
#
# ./tr_import_reconciled_tree.pl -i sandbox/pg17890_reconciled.nhx -u jestill --host localhost --dbname tr_test --driver mysql -s bowers_rosids --verbose
#

#-----------------------------+
# INCLUDES                    |
#-----------------------------+
use strict;
use DBI;
use Getopt::Long;
use Bio::TreeIO;                # BioPerl Tree I/O
use Bio::Tree::TreeI;
use File::Basename;           # Use this to extract base name from file path
# The following needed for printing help
use Pod::Select;               # Print subsections of POD documentation
use Pod::Text;                 # Print POD doc as formatted text file
use IO::Scalar;                # For print_help subfunction
use IO::Pipe;                  # Pipe for STDIN, STDOUT for POD docs
use File::Spec;                # Convert a relative path to an abosolute path

#-----------------------------+
# VARIABLES                   |
#-----------------------------+
my ($VERSION) = q$Rev: 603 $ =~ /(\d+)/;

my $infile;
my $in_path;                  # Modifed infile to inpath
my $format = "prime";         # Assumes reconciled trees in prime format
my $species_tree_name;        # Path for the species tree
my $cluster_set_name;         # Name of the cluseter set
                              # if integer this is the inteer of __
                              # as used in the database
                              # otherwise must look up from database.
my $species_tree_id;          # The integer id of the species tree in database
my $species_root_node_id;     # Root node of the species tree
my $species_tree_version;     # The integer version of the species tree

# DATABASE VARS
my $db;                       # Database name (ie. iplant_tr)
my $host;                     # Database host (ie. localhost)
my $driver;                   # Database driver (ie. mysql)
my $statement;                # Database statement
my $sth;                      # Database statement handle

# OPTIONS SET IN USER ENVIRONMENT
my $usrname = $ENV{TR_USERNAME};  # User name to connect to database
my $pass = $ENV{TR_PASSWORD};     # Password to connect to database
my $dsn = $ENV{TR_DSN};           # DSN for database connection

# BOOLEANS
my $quiet = 0;
my $verbose = 0;
my $show_help = 0;
my $show_usage = 0;
my $show_man = 0;
my $show_version = 0;
my $do_test = 0;                  # Run the program in test mode
my $do_convert_pr2db =0;             # Convert species nodes from prime ids
                                  # to ids as used in the database

#-----------------------------+
# COMMAND LINE OPTIONS        |
#-----------------------------+
my $ok = GetOptions(# REQUIRED OPTIONS
		    "i|infile|indir=s"  => \$in_path,
		    "s|species=s" => \$species_tree_name,
#		    "c|cluster=s" => \$cluster_set_name,
		    # This may need to be the species tree name
		    # used in the database. Assumes that the species
		    # tree is already in the database
		    # DSN REQUIRED UNLESS PARTS USED
                    "d|dsn=s"         => \$dsn,
		    # ALTERNATIVE TO --dsn 
		    "driver=s"        => \$driver,
		    "dbname=s"        => \$db,
		    "host=s"          => \$host,
		    # THE FOLLOWING CAN BE DEFINED IN ENV
		    "u|dbuser=s"      => \$usrname,
                    "p|dbpass=s"      => \$pass,
		    # ADDITIONAL OPTIONS
		    "format=s"    => \$format,
		    "q|quiet"     => \$quiet,
		    "verbose"     => \$verbose,
		    "convert-id"  => \$do_convert_pr2db,
		    # ADDITIONAL INFORMATION
		    "usage"       => \$show_usage,
		    "test"        => \$do_test,
		    "version"     => \$show_version,
		    "man"         => \$show_man,
		    "h|help"      => \$show_help,);

#-----------------------------+
# SHOW REQUESTED HELP         |
#-----------------------------+
if ( ($show_usage) ) {
#    print_help ("usage", File::Spec->rel2abs($0) );
    print_help ("usage", $0 );
}

if ( ($show_help) || (!$ok) ) {
#    print_help ("help",  File::Spec->rel2abs($0) );
    print_help ("help",  $0 );
}

if ($show_man) {
    # User perldoc to generate the man documentation.
    system ("perldoc $0");
    exit($ok ? 0 : 2);
}

if ($show_version) {
    print "\n$0:\n".
	"Version: $VERSION\n\n";
    exit;
}


#-----------------------------------------------------------+
# DATABASE CONNECTION                                       |
#-----------------------------------------------------------+

if ( ($db) && ($host) && ($driver) ) {
    # Set default values if none given at command line
    $db = "iplant_tr" unless $db; 
    $host = "localhost" unless $host;
    $driver = "mysql" unless $driver;
    $dsn = "DBI:$driver:database=$db;host=$host";
} 
elsif ($dsn) {
    # We need to parse the database name, driver etc from the dsn string
    # in the form of DBI:$driver:database=$db;host=$host
    # Other dsn strings will not be parsed properly
    # Split commands are often faster then regular expressions
    # However, a regexp may offer a more stable parse then splits do
    my ($cruft, $prefix, $suffix, $predb, $prehost); 
    ($prefix, $driver, $suffix) = split(/:/,$dsn);
    ($predb, $prehost) = split(/;/, $suffix);
    ($cruft, $db) = split(/=/,$predb);
    ($cruft, $host) = split(/=/,$prehost);
    # Print for debug
    print STDERR "\tPRE:\t$prefix\n" if $verbose;
    print STDERR "\tDRIVER:\t$driver\n" if $verbose;
    print STDERR "\tSUF:\t$suffix\n" if $verbose;
    print STDERR "\tDB:\t$db\n" if $verbose;
    print STDERR "\tHOST:\t$host\n" if $verbose;
}
else {
    # The variables to create a dsn have not been passed
    print STDERR "ERROR: A valid dsn can not be created\n";
#    print STDERR "No database specified" if (!$db);
#    print STDERR "No host specified" if (!$host);
#    print STDERR "No driver specified" if (!$driver);
    exit;
}

#-----------------------------+
# GET DB PASSWORD             |
#-----------------------------+
unless ($pass) {
    print "\nEnter password for the user $usrname\n";
    system('stty', '-echo') == 0 or die "can't turn off echo: $?";
    $pass = <STDIN>;
    system('stty', 'echo') == 0 or die "can't turn on echo: $?";
    chomp $pass;
}


#-----------------------------+
# CONNECT TO THE DATABASE     |
#-----------------------------+
# Commented out while I work on fetching tree structure
my $dbh = &connect_to_db($dsn, $usrname, $pass);

#-----------------------------------------------------------+
# LOAD THE ARRAY OF FILE PATHS                              |
#-----------------------------------------------------------+
my @input_files;
if ($in_path) {
    if (-f $in_path) {
	print STDERR "Input path is a file\n"
	    if $verbose;
	push (@input_files, $in_path);
    }
    elsif (-d $in_path) {
	
	# NOTE: If other input formats are added, change the following to always
	# default to fasta format. Current here to allow for
	# input from other types of data.
	print STDERR "Input path is a directory\n" 
	    if $verbose;
	
	# GET THE DIRECTORY VAR
	my $in_dir = $in_path;
	# Add slash to indir if needed
	unless ($in_dir =~ /\/$/ ) {
	    $in_dir = $in_dir."/";
	}
	
	# LOAD FILES IN THE INTPUT DIRECTORY
	# First load to tmp array so that indir can be prefixed to inpath
	my @tmp_file_paths;
	if ($format =~ "prime") {
	    opendir( DIR, $in_dir ) || 
		die "Can't open directory:\n$in_dir"; 
	    @tmp_file_paths = grep /\.nexus$|\.nhx$/, readdir DIR ;
	    closedir( DIR );
	}
	
	# DIR directory to path of 
	foreach my $tmp_file_path (@tmp_file_paths ) {
	    push (@input_files, $in_dir.$tmp_file_path);
	}
	
	# If no files found matching expected extensions, may want to
	# just push all files in the directory
	
	
    } else {
	print STDERR "Input path is not a valid directory or file:\n";
	die;
    }
    
} else {
    print STDERR "\a";
    print STDERR "WARNING: A input directory or file has not been specified\n";
}

#-----------------------------------------------------------+
# GET SPECIES TREE ID                                       |
#-----------------------------------------------------------+
# TO DO: MAKE FETCING SPECIES TREE A SUBFUNCTION
#
# CHECK HERE IF INPUT NAME IS INTEGER, IF IT IS AN INTEGER
# DO NOT ATTEMPT TO LOOK UP SPECIES NAME
print STDERR "\nIdentifying species tree from name: $species_tree_name\n"
    if $verbose;
$statement = "SELECT species_tree_id,version FROM species_tree".
    " WHERE species_tree_name = '".$species_tree_name."'";

print STDERR "\tSQL: ".$statement."\n" if $verbose;
my $species_tree_sth = &prepare_sth($dbh,$statement);
execute_sth($species_tree_sth);

my $species_tree_id_count = 0 ;

# If you are asking yourself why I did a fetchrow here when I 
# only wnat one thing, it is because in the future I may
# also want to return the version integer as well and make the
# decision about which one to use based on the version
# JCE 09/27/2010

while(my $row = $species_tree_sth->fetchrow_arrayref) {
    
    $species_tree_id_count++;
    ($species_tree_id,$species_tree_version) = @$row;

    print STDERR "\tSpecies tree id is: ".$species_tree_id."\n" if $verbose;
    if ($species_tree_version) {
	print STDERR "\tSpecies tree version is:".$species_tree_version."\n"
	    if $verbose;
    }
    else {
	print STDERR "\tSpecies tree version is null\n" if $verbose;
    }
}

# WE ONLY EXPECT ONE SPECIES TREE FOR THE GIVEN QUERY
if ($species_tree_id_count == 0) {
    # If the query for species tree name does not return a value
    # tell user the species tree name does not exist in the database
    # and exit
    my $error_msg = "ERROR: The species tree name ".$species_tree_name.
	" does not exist in the database selected.\n";
    if ($db) {
	$error_msg = $error_msg."The selected database is $db \n";
    }
    print STDERR $error_msg if $verbose;
}
elsif ($species_tree_id_count > 1) {
    print STDERR "ERROR: More than once species tree has been tagged with".
	" the name";
}



#-----------------------------------------------------------+
# PROCESS EACH GENE TREE FILE                               |
#-----------------------------------------------------------+
foreach my $infile (@input_files) {
    print STDERR "\n============================================\n"
	if $verbose;
    print STDERR "Processing:\t$infile\n"
	if $verbose;

    #-----------------------------+
    # GET THE FAMILY ID FOR       |
    # THIS FAMILY NAME            |
    # FAMILY NAME IS STABLE ID    |
    #-----------------------------+
    #////////////////////////////////////////////
    # ASSUMES THAT THE FAMLIY NAME DOES NOT 
    # ALREADY EXIST IN THE DATATABASE
    #////////////////////////////////////////////
    # Get filename from file name
    my @suffix_list = ("_reconciled.nhx",
		       "_reconciliation.nhx",);
    my $family_base_name = basename($infile,@suffix_list);
    my $family_stable_id = $family_base_name;
    my $family_id = stable_id_2_family_id($family_stable_id);

    print STDERR "Family name:\t".$family_base_name."\n"
	if $verbose;
    print STDERR "Family id:\t".$family_id."\n"
	if $verbose;
    print STDERR "============================================\n"
	if $verbose;

    #-----------------------------+
    # TREE OBJECT                 |
    #-----------------------------+
    my $tree_in = new Bio::TreeIO(-file   => $infile,
				  -format => $format)
	|| die "Can not open $format format tree file:\n$infile";
    
    #-----------------------------+
    # CYCLE THROUGH ALL TREES     |
    # IN RECONCILED TREE FILE     |
    #-----------------------------+
    # THERE SHOULD ONLY BE A SINGLE TREE IN THE TREE FILE OTHERWISE
    # THE FAMILY NAMES WILL NOT BE CORRECTLY ADDED TO THE DATABASE
    my $tree_num = 0;
    while( my $tree = $tree_in->next_tree ) {
	$tree_num++;
	
	my $tree_db_id;          # integer ID of the tree in the database
	my $node_db_id;          # integer ID of a node in the database
	my $edge_db_id;          # integer ID of an edge in the database
	
	print STDERR "\n=====================================================\n"
	    if $verbose;
	print STDERR " PROCESSING FILE: $infile\n" 
	    if $verbose;
	print STDERR " PROCESSING TREE NUM: $tree_num\n" 
	    if $verbose;
	print STDERR "=====================================================\n"
	    if $verbose;


	#-----------------------------+
	# ADD DATA TO PROTEN TREE     |
	# TABLE                       |
	#-----------------------------+
	my $statement = "INSERT INTO protein_tree (family_id)".
	    " VALUES".
	    " ('".$family_id."')";
	print STDERR "\tSQL: $statement\n"
	    if $verbose;

	my $insert_ptree_sth = &prepare_sth($dbh,$statement);
	&execute_sth($insert_ptree_sth);
	# Id of the protein tree
	my $ptree_id = &last_insert_id($dbh,"protein_tree", $driver);
	print STDERR "\tTree ID: $ptree_id\n" 
	    if $verbose;

#	#-----------------------------+
#	# ACCESS LEAF NODES IN TREE   |
#	#-----------------------------+
	my @leaf_nodes = $tree->get_leaf_nodes;
	my $num_leaf_nodes = @leaf_nodes;  

	print STDERR "\tLEAF NODES:\t$num_leaf_nodes\n"
	    if $verbose;
	my @all_nodes = $tree->get_nodes;
	my $num_nodes = @all_nodes;
	print "\tTOTAL NODES:\t$num_nodes\n"
	    if $verbose;
	
	#-----------------------------------------------------------+
	# ADD PROTEIN TREE NODES TO THE DATABASE                    |
	#-----------------------------------------------------------+
	$dbh->do("SET FOREIGN_KEY_CHECKS=0;");
	
	print STDERR "\n-----------------------------+\n" 
	    if $verbose;
	print STDERR " PROCESSING NODES\n"
	    if $verbose;
	print STDERR "-----------------------------+\n" 
	    if $verbose;
	
	foreach my $ind_node (@all_nodes) {


	    #-----------------------------+
	    # LOAD THE TREE ID WITH       |
	    # OTHER FIELDS BLANK          |
	    #-----------------------------+
	    # This gives a place to store the node
	    # and allows for a node_id to use later
	    $statement = "INSERT INTO protein_tree_node".
		" (protein_tree_id) VALUES (".$ptree_id.")";
	    print STDERR "\t\tSQL: $statement\n" 
		if $verbose;
	    $sth = &prepare_sth($dbh,$statement);
	    &execute_sth($sth);
	    my $ptree_node_id = &last_insert_id($dbh,"protein_tree", $driver);
	    print STDERR "\tDatabase tree id is : $ptree_node_id\n"
		if $verbose;
	    

		#-----------------------------+
		# SHOW PRIME ID               |
		#-----------------------------+
		if ($ind_node->get_tag_values("ID")) {
		    print STDERR "\t\tPRIME ID: ".
			$ind_node->get_tag_values("ID")."\n"
			if $verbose;
		    if ($ind_node->ancestor->get_tag_values("ID")) {
			print STDERR "\t\tPRIME ANCESTOR:".
			    $ind_node->ancestor->get_tag_values("ID")."\n"
			    if $verbose;
		    }
		}
		else {
		    print STDERR "\t\tNODE HAS NO PRIME ID\n"
			if $verbose;
		}


	    #-----------------------------+
	    # UPDATE PROTEIN TREE MEMBER
	    # TABLE FOR LEAF NODES
	    #-----------------------------+
	    if ($ind_node->is_Leaf) {
		# ASSUMES NAMES AS locusID_species

		print STDERR "\t\tUPDATING TREE MEMBER FOR NODE\n"
		    if $verbose;
		print STDERR "\t\tNode NAME:\t".$ind_node->id."\n" 
		    if $verbose;
		#/////////////////////////////////// 
		# WARNING
		# The following assumes locus id and 
		# species name are delimited by _
		# and no other _ characters occur
		# in the leaf node identifier
		#/////////////////////////////////// 
		my ($locus_id, $species_name) = split(/_/,$ind_node->id);
		
		my $member_id = stable_id_2_member_id($locus_id);
		
	        print STDERR "\t\tNode ID:\t".$ptree_node_id."\n"
		    if $verbose;
		print STDERR "\t\tMember ID:\t".$member_id."\n"
		    if $verbose;




		$statement = "INSERT INTO protein_tree_member".
		    " (node_id, member_id)".
		    " VALUES ".
		    " ('".$ptree_node_id."',".
		    "'".$member_id."')";
		print STDERR "\t\tSQL: $statement\n"
		    if $verbose;
		$sth = &prepare_sth($dbh,$statement);
		&execute_sth($sth);

	    }
	    
	    #-----------------------------+
	    # SET ID IN TREE OBJECT TO    |
	    # THE DATABASE ID             |
	    #-----------------------------+
	    # This will be used later to fetch db id of the 
	    # parent node
	    $ind_node->id($ptree_node_id) || 
		die "The Tree Object Node ID can not be set\n";


	} # End of for each node, loading nodes to database

	# Commit changes (not really, but need to start this)
	$dbh->commit();
	
    
	#-----------------------------------------------------------+
	# ADD PROTEIN TREE EDGES TO THE DATABASE                    |
	#-----------------------------------------------------------+
	# We are also adding root node to protein_tree_nod
	# if it is known
	
	print STDERR "\n-----------------------------+\n"
	    if $verbose;
	print STDERR " Processing Edges\n"
	    if $verbose;
	if ($tree->get_root_node) {
	    print STDERR " and setting root node\n"
		if $verbose;
	}
	print STDERR "-----------------------------+\n"
	    if $verbose;
	foreach my $ind_node (@all_nodes) {

	    # First check to see that an id exists
	    if ($ind_node->id) {
		my $anc = $ind_node->ancestor;
		
		# Only add edges when there is an ancestor node that has 
		# an id.
		if ($anc) {
		    if ($anc->id) {
			
			#-----------------------------+
			# ADD EDGE TO                 |
			# protein_tree_node           |
			#-----------------------------+
			$statement = "UPDATE protein_tree_node".
			    " SET parent_id = ".
			    " '".$anc->id."'".
			    " WHERE node_id =".
			    " '".$ind_node->id."'";
			
			print STDERR "\tSQL: $statement\n"
			    if $verbose;
			my $edge_sth = &prepare_sth($dbh,$statement);
			execute_sth($edge_sth);

			#-----------------------------+
			# ADD ROOT ID TO              |
			# protein_tree_node           |
			#-----------------------------+
			# WARNING
			# ASSUMES A SINGLE ROOT FOR EACH TREE
			if ($tree->get_root_node) {
			    my $root = $tree->get_root_node;
			    $statement = "UPDATE protein_tree_node".
				" SET root_id =".
				"'".$root->id."'".
				" WHERE node_id =".
				" '".$ind_node->id."'";
			    print STDERR "\tSQL: $statement\n"
				if $verbose;
			    my $set_root_sth = &prepare_sth($dbh,$statement);
			    execute_sth($set_root_sth);

			    #-----------------------------+
			    # ADD ROOT TO                 |
			    # protein_tree_member         |
			    # FOR LEAF NODES              |
			    #-----------------------------+
			    # WARNING
			    # ASSUMES A SINGLE ROOT FOR EACH TREE
			    if ($ind_node->is_Leaf) {
				$statement = "UPDATE protein_tree_member".
				    " SET root_id =".
				    "'".$root->id."'".
				    " WHERE node_id =".
				    " '".$ind_node->id."'";
				print STDERR "\tSQL: $statement\n"
				    if $verbose;
				my $set_root_sth = &prepare_sth($dbh,
								$statement);
				execute_sth($set_root_sth);

			    }

			} # End of if tree has root node
		    } # End of if ancestor has id 
		} # End of if the node has an ancestor
	    } # End of if node has id
	} # End of for each node in the tree

	$dbh->commit();

	#-----------------------------+
	# UPDATE ROOT NODE IN         |
	# protein_tree TABLE          |
	#-----------------------------+
	print STDERR "\nUpdating root data in protein_tree\n"
	    if $verbose;
	if ($tree->get_root_node) {
	    my $root = $tree->get_root_node;

	    $statement = "UPDATE protein_tree SET".
		" root_node_id =".
		" '".$root->id."'".
		" WHERE".
		" protein_tree_id =".
		" '".$ptree_id."'";

	    print STDERR "\tSQL: $statement\n"
		if $verbose;
	    my $set_root_sth = &prepare_sth($dbh,
					    $statement);
	    execute_sth($set_root_sth);
	    
	}

	#-----------------------------------------------------------+
	# PROCESS NODE ATTRIBUTES                                   |
	#-----------------------------------------------------------+
	# FOR PRIME FORMAT RECONCILIATION FILES THIS WILL
	# CONTAIN THE RECONCILIATIONS
	foreach my $ind_node (@all_nodes) {

	    #-----------------------------+
	    # BOOTSTRAP VALUE             |
	    #-----------------------------+
	    # In prime format ... these would be ultrametric distances?
	    # For the moment, these are being ignored and not doing
	    # anything with them since Sheldon's trees do not
	    # have bootstrap values
	    if ($ind_node->bootstrap) {
		print STDERR "\tBootstrap Value: ".
		    $ind_node->bootstrap."\n";
	    }

	    print STDERR "\tProcessing node: ".$ind_node->id."\n"
		if $verbose;
	    my @node_tags = $ind_node->get_all_tags;
	    foreach my $ind_tag (@node_tags) {
		print STDERR "\t\t".$ind_tag."--->"
		    if $verbose;
		print STDERR $ind_node->get_tag_values($ind_tag).""
		    if $verbose;
		print STDERR "\n"
		    if $verbose;

		# These node tags will need to be added to 
		# the table protein_tree_node_attribute
		my $cvterm_id = get_tr_cvterm_id($ind_tag);
		print STDERR "\t\t\tDB Src: ".$cvterm_id."\n"
		    if $verbose;

		#-----------------------------+
		# LOAD NODE TAG VALUE PAIRS   |
		# INTO                        |
		# protein_tree_node_attribute |
		#-----------------------------+
		$statement = "INSERT INTO protein_tree_node_attribute".
		    " ( node_id, cvterm_id, value )".
		    " VALUES".
		    " (".
		    " '".$ind_node->id."',".
		    " '".$cvterm_id."',".
		    " '".$ind_node->get_tag_values($ind_tag)."'".
		    " ) ";
		print STDERR "\t\t\t$statement\n"
		    if $verbose;
		my $set_atr_sth = &prepare_sth($dbh,$statement);
		execute_sth($set_atr_sth);

		#-----------------------------+
		# MAP NODES IN GENE TREE TO   |
		# NODES IN SPECIES TREE       |
		#-----------------------------+
		# If the individiual tag is AC ..
		if ($ind_tag =~ "AC") {
		    print STDERR "\t\t\tMAPPING GUEST NODE TO HOST NODE:\n"
			if $verbose;
		    
		    # The ac list gives the node
		    my @ac = split(/\s/,
				   $ind_node->get_tag_values($ind_tag));


		    # The ac list is from the most derived node
		    # to the most ancestral node
		    my $num_ac = @ac;
		    # The ancestral ac node should therefore be the 
                    # first in the list
		    my $pr_der_ac = $ac[0];            # Most derived (PRIME)
		    my $pr_anc_ac = $ac[$num_ac - 1];  # Most ancestral (PRIME)
		    print STDERR "\t\t\tPRIME Ancestral: $pr_anc_ac\n"
			if $verbose;

                    # Most ancestral DB Identefire of node(DBID)
		    my $db_anc_ac = prime_2_db($pr_anc_ac);
		    print STDERR "\t\t\tDB Ancestral: $db_anc_ac\n"
			if $verbose;
		}


	    }
	    
	} # End of for each individual node, loading tag value pairs


	#-----------------------------------------------------------+
	# LOAD RECONCILIATIONS                                      |
	#-----------------------------------------------------------+

	# FIRST INSERT VALS INTO
	print STDERR "\n-----------------------------+\n"
	    if $verbose;
	print STDERR " LOADING RECONCILIATIONS\n"
	    if $verbose;
	print STDERR "-----------------------------+\n"
	    if $verbose;
	print STDERR "Species Tree ID: $species_tree_id\n"
	    if $verbose;
	print STDERR "Protein Tree ID: $ptree_id\n"
	    if $verbose;

	#-----------------------------+
	# LOAD VALS TO THE TABLE      |
	# reconciliation              |
	#-----------------------------+
	# This table serves to connect species trees to gene trees
	# in the database
	$statement = "INSERT INTO reconciliation".
	    " ( protein_tree_id, species_tree_id )".
	    " VALUES".
	    " (".
	    " '".$ptree_id."',".
	    " '".$species_tree_id."'".
	    " )";
	print STDERR "SQL: $statement\n"
	    if $verbose;
	$sth = &prepare_sth($dbh,$statement);
	&execute_sth($sth);
	my $reconciliation_id = &last_insert_id($dbh,"protein_tree", $driver);
	print STDERR "Reconciliation ID: $reconciliation_id\n"
	    if $verbose;


	#-----------------------------------------------------------+
	# MAP NODES FROM GENE TREE TO LOCATIONS IN SPECIES TREE     |
	#-----------------------------------------------------------+
	foreach my $ind_node (@all_nodes) {
	    
	    print "\nMapping Reconciled Node: ".$ind_node->id."\n"
		if $verbose;

	    my $host_child;   # The parent node in the species tree
	    my $host_parent;  # The child node in the species tree
	    my $on_node;      # Gene node maps to species node

	    if ( $ind_node->get_tag_values("AC") ) {
		#-----------------------------+
		# g(i) hasAC IS TRUE          |
		#-----------------------------+
		#print STDERR "\thas AC\n"
		#    if $verbose;

		# SPLIT AC INTO ITS COMPONENT PARTS
		my @ac = split(/\s/, $ind_node->get_tag_values("AC"));
		my $num_ac = @ac;
		my $ac_1 = $ac[0];  # Most derived, 1st element in ac ary

		print STDERR "\tPRIME AC: ". 
		    $ind_node->get_tag_values("AC")."\n" 
		    if $verbose;
		print STDERR "\tNUM AC $num_ac\n"
		    if $verbose;
		print STDERR "\tPRIME AC: $ac_1\n"
		    if $verbose;


		#/////////////////////////////////////////////////
		# WARNING:
		# IF WE NEED TO MAP BETWEEN THE PRIMEID AND
		# THE ID IN THE DATABASE
		#/////////////////////////////////////////////////
		$ac_1 = prime_2_db($ac_1);

		#-----------------------------+
		#  g(i) IS A LEAF NODE        |
		#-----------------------------+
		if ($ind_node->is_Leaf) {
		    print STDERR "\tis a Leaf node\n"
			if $verbose;
		    
		    $host_child = $ac_1;
		    $host_parent = $ac_1;
		    $on_node = "TRUE";

		    print STDERR "\t\tHC: ".$host_child."\n"
			if $verbose;
		    print STDERR "\t\tHP: ".$host_parent."\n"
			if $verbose;
		    print STDERR "\t\tON: ".$on_node."\n"
			if $verbose;

		    $statement = "INSERT INTO reconciliation_node".
			" (".
			" reconciliation_id,".
			" node_id,".
			" host_parent_node_id,".
			" host_child_node_id,".
			" is_on_node".
			" )".
			" VALUES".
			" (".
			" '".$reconciliation_id."',".
			" '".$ind_node->id."',".
			" ".$host_parent.",".
			" ".$host_child.",".
			" $on_node".
			" )";
		    print "\tSQL: ".$statement."\n"
			if $verbose;


		    $sth = &prepare_sth($dbh,$statement);
		    &execute_sth($sth);
		    # The reconciliation node id in the database (rn_id)
		    # Getting this here in case we want to add reconciliation
		    # node attributes such as type of duplicationx
		    my $rn_id = &last_insert_id($dbh,
						"reconciliation_node", 
						$driver);


		    # Since leaf nodes have all the information we
		    # need in their own AC .. we can move on to next node
		    # in the gene tree
		    next;

		}
		else {
		    print STDERR "\tIs not a leaf\n"
			if $verbose;
		    $host_parent = $ac_1;
		}

	    }
	    else {
		#-----------------------------+
		# g(i) has AC IS FALSE        |
		#-----------------------------+
#		print STDERR "\tNO AC\n";
#		# GET ANCESTRAL NODES

		# TEST OF SUBFUNCTION WITH NO RETURNS HERE
		my $ancestral_ac = &get_ancestral_ac ($ind_node);
		print STDERR "\tANCESTAL AC VALUE: $ancestral_ac\n"
		    if $verbose;
		# NEED TO CONVERT THIS INTEGER FROM PRIME AC
		# VALUE TO PROPER NODE ID FROM THE DATABASE
		# IN THE FUTURE THIS COULD BE AVOIDED BY TAGGING THE IDS
		# IN THE SPECIES TREE AS THE NODE IDS FROM THE DATABASE
		$ancestral_ac = prime_2_db($ancestral_ac);
		print STDERR "\tAncestral AC converted to $ancestral_ac\n"
		    if $verbose;
		$host_parent = $ancestral_ac;

	    } # END OF g(i) has AC



	    #///////////////////////
	    #
	    # CHECK IF NODE IS A DUPLICATION
	    #
	    #///////////////////////
	    # WARNING:
	    # THIS RELIES ON DUPLICATION STATUS TAG IN THE
	    # PRIME FILE, IF THIS TAG IS NOT PRESENT
	    # THIS WILL NOT WORK!!
	    #///////////////////////
	    if ($ind_node->get_tag_values("D") ) {
		if ( $ind_node->get_tag_values("D") =~ "1" ) {
		    #print STDERR "NODE IS A DUPLICATION\n";
		    $on_node = "FALSE";
		    #exit;
		}
		else {
		    $on_node = "TRUE";
		}
	    }
	    else {
		$on_node = "TRUE";
	    }


	    if ($on_node =~ "FALSE") {
		#-----------------------------+
		# GET A CHILD NODE AC         |
		#-----------------------------+
		# FOR NODES MAPPING TO EDGES
		# Any child node should work
		my $child_ac = &get_child_ac($ind_node);
		print STDERR "\tCHILD AC VALUE: $child_ac\n"
		    if $verbose;
		# This must be converted from prime format to node_id
		# as store in the database
		$child_ac = prime_2_db($child_ac);

		$host_child = $child_ac;
	    }
	    else {
		# These are the gene tree nodes that are mapping
		# to species tree nodes
		$host_child = $host_parent;
	    }
	    
	    print STDERR "\t\tON:".$on_node."\n"
		if $verbose;

	    #-----------------------------+
	    # UPDATE DATABASE FOR         |
	    # NOT LEAF NODES              |
	    #-----------------------------+
	    # // The following code is redundant with insert statement
	    #    for the leaf nodes above, this can be cleaned up
	    #    by making this subfunction.

	    print STDERR "\t\tHC: ".$host_child."\n"
		if $verbose;
	    print STDERR "\t\tHP: ".$host_parent."\n"
		if $verbose;
	    print STDERR "\t\tON: ".$on_node."\n"
		if $verbose;
	    
	    $statement = "INSERT INTO reconciliation_node".
		" (".
		" reconciliation_id,".
		" node_id,".
		" host_parent_node_id,".
		" host_child_node_id,".
		" is_on_node".
		" )".
		" VALUES".
		" (".
		" '".$reconciliation_id."',".
		" '".$ind_node->id."',".
		" ".$host_parent.",".
		" ".$host_child.",".
		" $on_node".
		" )";
	    print "\tSQL: ".$statement."\n"
		if $verbose;
	    
	    
	    $sth = &prepare_sth($dbh,$statement);
	    &execute_sth($sth);
	    # The reconciliation node id in the database (rn_id)
	    # Getting this here in case we want to add reconciliation
	    # node attributes such as type of duplicationx
	    my $rn_id = &last_insert_id($dbh,
					"reconciliation_node", 
					$driver);
	    
	    #// END REDUNDANT CODE



	} # END OF FOR EACH NODE IN TREE, Mapping reconciled nodes

	
    } # End of for each tree in intput file
    
} # End of for each file in the input path


exit;

#-----------------------------------------------------------+
# SUBFUNCTIONS
#-----------------------------------------------------------+


sub print_help {
    my ($help_msg, $podfile) =  @_;
    # help_msg is the type of help msg to use (ie. help vs. usage)
    
    print "\n";
    
    #-----------------------------+
    # PIPE WITHIN PERL            |
    #-----------------------------+
    #my $podfile = $0;
    my $scalar = '';
    tie *STDOUT, 'IO::Scalar', \$scalar;
    
    if ($help_msg =~ "usage") {
	podselect({-sections => ["SYNOPSIS|MORE"]}, $0);
    }
    else {
	podselect({-sections => ["SYNOPSIS|ARGUMENTS|OPTIONS|MORE"]}, $0);
    }

    untie *STDOUT;
    # now $scalar contains the pod from $podfile you can see this below
    #print $scalar;

    my $pipe = IO::Pipe->new()
	or die "failed to create pipe: $!";
    
    my ($pid,$fd);

    if ( $pid = fork() ) { #parent
	open(TMPSTDIN, "<&STDIN")
	    or die "failed to dup stdin to tmp: $!";
	$pipe->reader();
	$fd = $pipe->fileno;
	open(STDIN, "<&=$fd")
	    or die "failed to dup \$fd to STDIN: $!";
	my $pod_txt = Pod::Text->new (sentence => 0, width => 78);
	$pod_txt->parse_from_filehandle;
	# END AT WORK HERE
	open(STDIN, "<&TMPSTDIN")
	    or die "failed to restore dup'ed stdin: $!";
    }
    else { #child
	$pipe->writer();
	$pipe->print($scalar);
	$pipe->close();	
	exit 0;
    }
    
    $pipe->close();
    close TMPSTDIN;

    print "\n";

    exit 0;
   
}


sub connect_to_db {
    my ($cstr) = @_;
    return connect_to_mysql(@_) if $cstr =~ /:mysql:/i;
    return connect_to_pg(@_) if $cstr =~ /:pg:/i;
    die "can't understand driver in connection string: $cstr\n";
}

sub connect_to_pg {

	my ($cstr, $user, $pass) = @_;
	
	my $dbh = DBI->connect($cstr, $user, $pass, 
                               {PrintError => 0, 
                                RaiseError => 1,
                                AutoCommit => 0});
	$dbh || &error("DBI connect failed : ",$dbh->errstr);

	return($dbh);
} # End of ConnectToPG subfunction


sub connect_to_mysql {
    
    my ($cstr, $user, $pass) = @_;
    
    my $dbh = DBI->connect($cstr, 
			   $user, 
			   $pass, 
			   {PrintError => 0, 
			    RaiseError => 1,
			    AutoCommit => 0});
    
    $dbh || &error("DBI connect failed : ",$dbh->errstr);
    
    return($dbh);
}

sub prepare_sth {
    my $dbh = shift;
#    my ($dbh) = @_;
    my $sth = $dbh->prepare(@_);
    die "failed to prepare statement '$_[0]': ".$dbh->errstr."\n" unless $sth;
    return $sth;
}

sub execute_sth {
    
    # I would like to return the statement string here to figure 
    # out where problems are.
    
    # Takes a statement handle
    my $sth = shift;

    my $rv = $sth->execute(@_);
    unless ($rv) {
	$dbh->disconnect();
	die "failed to execute statement: ".$sth->errstr."\n"
    }
    return $rv;
} # End of execute_sth subfunction

sub last_insert_id {

    #my ($dbh,$table_name,$driver) = @_;
    
    # The use of last_insert_id assumes that the no one
    # is interleaving nodes while you are working with the db
    my $dbh = shift;
    my $table_name = shift;
    my $driver = shift;

    # The following replace by sending driver info to the sufunction
    #my $driver = $dbh->get_info(SQL_DBMS_NAME);
    if (lc($driver) eq 'mysql') {
	return $dbh->{'mysql_insertid'};
    } 
    elsif ((lc($driver) eq 'pg') || ($driver eq 'PostgreSQL')) {
	my $sql = "SELECT currval('${table_name}_pk_seq')";
	my $stmt = $dbh->prepare_cached($sql);
	my $rv = $stmt->execute;
	die "failed to retrieve last ID generated\n" unless $rv;
	my $row = $stmt->fetchrow_arrayref;
	$stmt->finish;
	return $row->[0];
    } 
    else {
	die "don't know what to do with driver $driver\n";
    }
} # End of last_insert_id subfunction

# The following pulled directly from the DBI module
# this is an attempt to see if I can get the DSNs to parse 
# for some reason, this is returning the driver information in the
# place of scheme
sub parse_dsn {
    my ($dsn) = @_;
    $dsn =~ s/^(dbi):(\w*?)(?:\((.*?)\))?://i or return;
    my ($scheme, $driver, $attr, $attr_hash) = (lc($1), $2, $3);
    $driver ||= $ENV{DBI_DRIVER} || '';
    $attr_hash = { split /\s*=>?\s*|\s*,\s*/, $attr, -1 } if $attr;
    return ($scheme, $driver, $attr, $attr_hash, $dsn);
}

sub stable_id_2_member_id {
    
    # Get the member_id of a locus in the database given
    # its stable_id
    my $stable_id_search = shift;
    my $member_id_result;

    my $search_sql = "SELECT member_id FROM member".
	" WHERE stable_id = '".$stable_id_search."'";
#    print STDERR "\t\tSQL:".$search_sql."\n" 
#	if $verbose;
    my $sth = $dbh->prepare($search_sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_arrayref) {
	$member_id_result = @$row[0];
    }

    unless ($member_id_result) {
#	print STDERR "\t\tNot in database\n";
	$member_id_result = 0;
    }
    
    return $member_id_result;

}


sub stable_id_2_family_id {
    
    # Get the family_id of a family in the database?
    # its stable_id
    my $stable_id_search = shift;
    my $family_id_result;

    my $search_sql = "SELECT family_id FROM family".
	" WHERE stable_id = '".$stable_id_search."'";
#    print STDERR "\t\tSQL:".$search_sql."\n" 
#	if $verbose;
    my $sth = $dbh->prepare($search_sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_arrayref) {
	$family_id_result = @$row[0];
    }

    unless ($family_id_result) {
#	print STDERR "\t\tNot in database\n";
	$family_id_result = 0;
    }
    
    return $family_id_result;

}

# This is currently a fake subfunction
# the real subfuction would look up terms in the context of
# the controlled vocabulary of the database
# This needs to be rewritten to look up terms in database under the
# prime_tags namespace
sub get_tr_cvterm_id {
    
    my $in_tag = shift;
    my %src_ids = 
	("AC" => "265",   #  Anti chain mapping                   [INT LIST]
	 "ID" => "268",   # Id of node in gene tree               [INT]
	 "S" => "267",    # Species of leaf node host             [STRING]
	 "D" => "266",    # Duplication                           [BOOLEAN]
	 "NT" => "269",   # Node time, t since root bifercation   [FLOAT]
	 "ET" => "270",   # Edge time, t since last bifercation   [FLOAT]
	 "BL" => "271"    # Branch length, reserverved term       [FLOAT]
	);
    my $src_id;
    $src_id = $src_ids{"$in_tag"} || "unknown";
    return $src_id;

    # Used 1 - 7 as initial placeholders for these
    # These were manually updated
    # UPDATE protein_tree_node_attribute SET cvterm_id = 267 WHERE cvterm_id = 3;
    # UPDATE protein_tree_node_attribute SET cvterm_id = 265 WHERE cvterm_id = 1;
    # UPDATE protein_tree_node_attribute SET cvterm_id = 268 WHERE cvterm_id = 2;
    # UPDATE protein_tree_node_attribute SET cvterm_id = 266 WHERE cvterm_id = 4;

}

sub prime_2_db {
    # TAKES A PRIME TV NODE ID AS INPUT AND RETURNS
    # THE DATABASE ID AS USED IN species_tree_node
    # This will be used to map IDs between the AC values
    # as derived from the PRIME format file and the valus
    # for species nodes in the database.
    # This is a temporary fix.
    # The best way to deal with this in the future would
    # be to make us of database IDs from the host tree with the ID tag in the
    # intput files for primetv or other reconciliation programs

    my $in_prime = shift;
    
    my %node_ids = 
	( "10" => "1",
	  "9" => "3",
	  "8" => "9",
	  "7" => "11",
	  "6" => "10",
	  "5" => "4",
	  "4" => "6",
	  "3" => "8",
	  "2" => "7",
	  "1" => "5",
	  "0" => "2",
	  "NULL" => "NULL",
	);
    my $db_id;
    $db_id = $node_ids{"$in_prime"} || "NULL";
    # Uncomment the following on if node parsing is having trouble
#    if ($db_id =~ "NULL") {
#	print STDERR "Don't know: $in_prime \n";
#    }
    return $db_id;

}

sub get_ancestral_ac {

    # This will return the most derived node of the ancestral
    # AC array and NOT The entire AC array

    # The node that is being searched as ancestral
    my $search_node = shift;

    # If it has an ancestral node
    if ($search_node->ancestor) {
	#-----------------------------+
	# NODE HAS PARENT             |
	#-----------------------------+
#	print STDERR "NODE DOES HAVE ANCESTOR\n"
#	    if $verbose;
	my $anc_node = $search_node->ancestor;

	#-----------------------------+
	# ANCESTOR DOES HAVE AC       |
	#-----------------------------+
	if ( $anc_node->get_tag_values("AC") ) {
	    print STDERR "\tFound ancestor with AC values\n"
		if $verbose;
	    # SPLIT AC INTO ITS COMPONENT PARTS
	    # AND RETURN MOST DERIVED
	    my @ac = split(/\s/, $anc_node->get_tag_values("AC"));
	    my $num_ac = @ac;
	    my $ac_1 = $ac[0];  # Most derived, 1st element in ac ary
	    my $ac_max = $ac[$num_ac];
	    return $ac_1;
 	}
	#-----------------------------+
	# ANCESTOR DOES NOT HAVE AC   |
	#-----------------------------+
	# Keep searching back tree
	else {
	    get_ancestral_ac($anc_node);
	}

    }
    else {
	#-----------------------------+
	# NODE DOES NOT HAVE ANCESTOR |
	#-----------------------------+
	# This should be the root node of the tree
	return "NULL";

    }

    
}

sub get_child_ac {
    # This will return the most ancestral ac of the child node
    # and NOT the entire AC array. 

    # The node that is being searched for child nodes
    my $search_node = shift;

    for my $child_node ($search_node->each_Descendent) {

#	print STDERR "\t\tChecking out:".$child_node->id."\n"
#	    if $verbose;
	
	if ( $child_node->get_tag_values("AC") ) {
	    #-----------------------------+
	    # CHILD NODE HAS AC           |
	    #-----------------------------+
	    # SPLIT AC INTO ITS COMPONENT PARTS
	    # AND RETURN MOST ANCESTRAL
#	    print STDERR "\t\tAC: ".$child_node->get_tag_values("AC")."\n"
#		if $verbose;
	    my @ac = split(/\s/, $child_node->get_tag_values("AC"));
	    my $num_ac = @ac;
	    # The max position in the AC array, this is the most ancestral
	    # node in the species tree in the AC list
	    my $max = $num_ac - 1;
#	    print STDERR "\t\tFetching AC val ".$max."\n"
#		if $verbose;
	    my $ac_1 = $ac[0];  # Most derived, 1st element in ac ary
	    my $ac_max = $ac[$max];
	    return $ac_max;
	}
	else {
	    #-----------------------------+
	    # CHILD NODE DOES NOT HAVE AC |
	    #-----------------------------+
	    # GET AC FROM CHILD NODE OF CHILD
#	    print STDERR "Child node does not have AC\n"
#		if $verbose;
	    get_child_ac($child_node);
	}

    }

}

__END__

=head1 NAME

tr_import_reconciled_tree.pl - Import reconciled tree to database

=head1 VERSION

This documentation refers to tr_import_reconciled_tree.pl version $Rev: 603 $

=head1 SYNOPSIS

=head2 Usage

    tr_import_reconciled_tree.pl -i infile_reconciled.nhx -s species_tree

=head2 Required Arguments

    --infile, -i     # Path to the reconciled file in PRIME nhx format
    OR
    --indir, -i       # Path to the directory of reconciled files
                      # These must be in PRIME format
    -s                # Name of the species tree in the reconciliation
                      # This tree should already exist in the database

=head1 DESCRIPTION

Imports reconciled gene trees in PRIME nhx format to the tree reconciliation
database.

=head1 REQUIRED ARGUMENTS

=over 2

=item -i, --infile

Path of the reconciled tree file.

=item -s, --species

Name of the species tree in the database that is used for the reconciliation.

=item --driver

The database driver to use. This will mysql.

=item --dbname

The name of the database that is being populated

=item --host

The host for the database connection.

=item -u, --dbuser

The user name for connecting to the database. This can also be set with the
TR_USERNAME variable in the user environment.

=item -p, --dbpass

This can also be set witg the TR_PASSWORD variable in the user environment. 
If not specified at the command line or in the environment, this will be
prompted for.

=back

=head1 OPTIONS

=over 2

=item --usage

Short overview of how to use program from command line.

=item --help

Show program usage with summary of options.

=item --version

Show program version.

=item --man

Show the full program manual. This uses the perldoc command to print the 
POD documentation for the program.

=item -q,--quiet

Run the program with minimal output.

=back

=head1 EXAMPLES

The following are examples of how to use this script

=head2 Import Single Tree

Before a gene tree can be imported, the species tree that the gene tree
is reconciled to must already exist in the database. To import a single 
gene tree named pg17890_reconciled.nhx that has been reconciled against 
the species tree named 'bowers_rosids':

  ./tr_import_reconciled_tree.pl -i sandbox/pg17890_reconciled.nhx 
                                 --format prime -s bowers_rosids
                                 --dbname tr_test --driver mysql 
                                 -s bowers_rosids 

=head2 Import Directory of Reconciled Trees

It is also possible to import all reconciled trees in a single directory.
The species tree that the gene trees are reconciled to must already
exist in the database, and all reconciled trees in the directory
must be reconciled to the same species tree.
For example, to import all reconciled trees in the directory
'my_reconciled_trees' that were reconciled to the species tree
named 'bowers_rosids':

  ./tr_import_reconciled_tree.pl -i my_reconciled_trees/ 
                                 --format prime -s bowers_rosids
                                 --dbname tr_test --driver mysql 
                                 -s bowers_rosids 

=head1 DIAGNOSTICS

=over 2

=item * Expecting input from STDIN

If you see this message, it may indicate that you did not properly specify
the input sequence with -i or --infile flag. NOTE: This program does not
currently supporte input from STDIN.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Many of the options passed at the command line can be set as 
options in the user's environment. 

=over 2

=item TR_USERNAME

User name to connect to the database.

=item TR_PASSWORD

Password for the database connection

=item TR_DBNAME

Database name.

=item TR_HOST

Host for the database connection.

=item TR_DSN

Full database DSN for connecting to a tree reconciliatin database.

=back

For example in the bash shell this would be done be editing your .bashrc file
to contain :

    export TR_USERNAME=yourname
    export TR_PASSWORD=yourpassword
    export TR_DBNAME=your_database_name
    export TR_DBHOST=localhost

Alternatively, the database name and host can be specified in a
DSN similar to the following format.

    export DBI_DSN='DBI:mysql:database=biosql;host-localhost'

=head1 DEPENDENCIES

=head2 Perl Modules

* BioPerl

This program depends on the BioPerl TreeIO module.

=head1 BUGS AND LIMITATIONS

=head2 Bugs

Please report bugs to:
http://pods.iplantcollaborative.org/jira

=head2 Limitations

Currently the tree_reconciliation database is limited to the MySQL RDBMS.

The reconcild trees used by this program must be in the PRIME format.
PRIME format trees from the Treebest program can be imported by using
the reconcile program included in the PRIME application download.

=head1 SEE ALSO

The tr_import_reconciled_tree.pl is a component of the iPlant Tree
Reconciliaton suite of utilities. Additoinal information is available
at:
L<https://pods.iplantcollaborative.org/wiki/display/iptol/1.0+Architecture>

=head1 LICENSE

Simplified BSD License:
http://tinyurl.com/iplant-tr-license

=head1 AUTHOR

James C. Estill E<lt>JamesEstill at gmail.comE<gt>

=head1 HISTORY

STARTED: 09/15/2010

UPDATED: 03/29/2011

VERSION: $Rev: 603 $

=cut

