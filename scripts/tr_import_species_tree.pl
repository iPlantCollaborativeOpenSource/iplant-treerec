#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           |
# tr_import_species_tree.pl                                 |
#                                                           |
#-----------------------------------------------------------+
#                                                           |
# CONTACT: JamesEstill_at_gmail.com                         |
# STARTED: 09/15/2010                                       |
# UPDATED: 04/12/2011                                       |
#                                                           |
# DESCRIPTION:                                              | 
#  Import species tree data to tree reconciliation database |
#  Edge attributes and node attributes are currently not    |
#  imported.                                                |
#                                                           |
# LICENSE:                                                  |
#  GNU Lesser Public License                                |
#  http://www.gnu.org/licenses/lgpl.html                    |  
#                                                           |
#-----------------------------------------------------------+
#
# WORKING EXAMPLE
# ./tr_import_species_tree.pl -i sandbox/species_for_primetv.nwk -u jestill --host localhost --dbname tr_test --driver mysql -t bowers_rosids
# TO DO;
#  * Add root node tag if needed
#    This would be stored in the tree table and as such would
#    require that there be a single root node per tree. Otherwise
#    could store the root node in a separate table.
#  * Root node will be used for tree optimization
#
#
# TEST USE:
# ./tr_import_species_tree.pl -i sandbox/species_for_primetv.nwk --verbose
#
# NOW TESTING WITH DB CONNECTION:
# ./tr_import_species_tree.pl -i sandbox/species_for_primetv.nwk -u jestill --host localhost --dbname tr_test --driver mysql -n bowers_rosids
#
#
# Will assume test database name is iplant_tr
# The MySQL versions tested on include:
# Ver 14.14 Distrib 5.1.46, for apple-darwin9.8.0 (i386) 
#
# Tables and data loaded:
#   * species_tree
#        - The unique identifier of the species tree.
#   * species_tree_attribute
#        - The name of the species tree. "bowers_rosids"
#   * species_tree_node
#        - Unique identifier for each node in the species tree
#   * species_tree_node_attribute
#        - Attributes of nodes such as node_id as used to specifiy nodes by
#          the PrimeTV format
#   * species_tree_node_path
#        - The edge between the child and parent nodes
#
#-----------------------------+
# INCLUDES                    |
#-----------------------------+
use strict;
use DBI;
use Getopt::Long;
use Bio::TreeIO;                # BioPerl Tree I/O
use Bio::Tree::TreeI;
# The following needed for printing help
use Pod::Select;               # Print subsections of POD documentation
use Pod::Text;                 # Print POD doc as formatted text file
use IO::Scalar;                # For print_help subfunction
use IO::Pipe;                  # Pipe for STDIN, STDOUT for POD docs
use File::Spec;                # Convert a relative path to an abosolute path

#-----------------------------+
# VARIABLES                   |
#-----------------------------+
my ($VERSION) = q$Rev: 614 $ =~ /(\d+)/;

my $infile;
my $format = "newick";        # Assumes reconciled trees in nhx format
my $species_tree_file;        # Path for the species tree

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

# Optional data for the tree
my $tree_name;                    # Name for species_tree_attributes table
my $tree_version;                 # Tree version number to assign

#-----------------------------+
# COMMAND LINE OPTIONS        |
#-----------------------------+
my $ok = GetOptions(# REQUIRED OPTIONS
		    "i|infile=s"      => \$infile,
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
		    "t|tree-name=s"   => \$tree_name,
		    "tree-version=i"  => \$tree_version,
		    "format=s"        => \$format,
		    "q|quiet"         => \$quiet,
		    "verbose"         => \$verbose,
		    # ADDITIONAL INFORMATION
		    "usage"           => \$show_usage,
		    "test"            => \$do_test,
		    "version"         => \$show_version,
		    "man"             => \$show_man,
		    "h|help"          => \$show_help,);

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
    $db = "biosql" unless $db; 
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
    print "ERROR: A valid dsn can not be created\n";
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
# WORK WITH THE TREE
#-----------------------------------------------------------+
my $tree_in = new Bio::TreeIO(-file   => $infile,
			      -format => $format) ||
    die "Can not open $format format tree file:\n$infile";

# CYCLE THROUGH NODES
my $tree_num = 0;
while( my $tree = $tree_in->next_tree ) {
    $tree_num++;

    my $tree_db_id;          # integer ID of the tree in the database
    my $node_db_id;          # integer ID of a node in the database
    my $edge_db_id;          # integer ID of an edge in the database

    print STDERR "\n----------------------------------------------\n" 
	if $verbose; 
    print STDERR "PROCESSING TREE NUM: $tree_num\n" if $verbose;


    #-----------------------------------------------------------+
    # MAY WANT TO FETCH INTEGER IDS FOR THE TAXA HERE           |
    #-----------------------------------------------------------+
    my @taxa = $tree->get_leaf_nodes;
    my $num_tax = @taxa;  
    print STDERR "NUM TAXA:\t$num_tax\n";
    
    #//////////////////////////////////////////////////////
    # TO DO: Add check here to see if name already exists
    #        in the DB and allow user to set new name if
    #        a conflict exists or increment version
    #        number for this tree OR stop import here.
    #\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    unless ($tree_name) {
	if ($tree->id) {
	    $tree_name = $tree->id;
	}
    }

    if ($tree_name) {
	print STDERR "TREE NAME:\t$tree_name\n";
    }
    else {
	# MAY CHOOSE TO MAKE THE TREE NAME A REQUIRED INPUT
	# COMMENT OUT THE FOLLOWING FOR THIS
	#print STDERR "\a"; # Sound alarm
	#print "\nERROR: A tree name must be part of the input file or".
	#    " entered at the command line using the --tree option.\n".
	#    " For more information use:\n$0 -h\n\n";
	#$dbh->disconnect();
	#exit;
    }

    my @all_nodes = $tree->get_nodes;
    
    my $num_nodes = @all_nodes;

    print STDERR "NUM NODES: $num_nodes\n" if $verbose;
    print STDERR "----------------------------------------------\n\n" 
	if $verbose; 

    #-----------------------------------------------------------+
    # ADD TREE INFORMATION TO THE DATABASE                      |
    #-----------------------------------------------------------+
    $dbh->do("SET FOREIGN_KEY_CHECKS=0;");

    # Will currently not attempt to set the version number, this would
    # require checking to see if the name already exists and then
    # potentially incrementing from the max value of versions already
    # existing.
    $statement = "INSERT INTO species_tree".
	" (species_tree_name)".
	" VALUES ('".$tree_name."')";

    print STDERR "SQL: \n $statement \n\n" 
	if $verbose;

    # INSERT AND GET TREE ID FOR DATABASE
    $sth = &prepare_sth($dbh,$statement);
    &execute_sth($sth);
    $tree_db_id = &last_insert_id($dbh,"tree", $driver);
    print STDERR "Database tree id is : $tree_db_id\n"
	if $verbose;

    #/////////////////////////////////////////////////////
    # ADDITIONAL INFORMATION FOR SPECIES TREE
    # WOULD BE LOADED TO species_tree_attribute HERE
    #/////////////////////////////////////////////////////
    
    # TURN FK CHECKS BACK ON AND COMMIT CHANGES
    $dbh->do("SET FOREIGN_KEY_CHECKS=0;");
    $dbh->commit();
    
    #-----------------------------------------------------------+
    # LOAD NODES TO THE DATABASE
    #-----------------------------------------------------------+
    print STDERR "\n-----------------------------+\n" 
	if $verbose;
    print STDERR "PROCESSING NODES\n"
	if $verbose;
    print STDERR "-----------------------------+\n" 
	if $verbose;

    foreach my $ind_node (@all_nodes) {
	
	# FIRST LOAD THE TREE ID WITH OTHER FIELDS BLANK
	$statement = "INSERT INTO species_tree_node".
	    " (species_tree_id) VALUES (".$tree_db_id.")";
	print STDERR "SQL: $statement\n" 
	    if $verbose;
	$sth = &prepare_sth($dbh,$statement);
	&execute_sth($sth);

	# Get the node id
	my $node_db_id = &last_insert_id($dbh, "species_tree_node", $driver);
	
	# Add node label if it exists in the tree object
	if ($ind_node->id) {
	    $statement = "UPDATE species_tree_node SET".
		" label = ? WHERE species_tree_node_id = ?";
	    $sth = &prepare_sth($dbh,$statement);
	    execute_sth($sth, $ind_node->id, $node_db_id );
	}

	# If this is a leaf node, check to see if the node label
	# is actually a taxon name and genbank id that we can reference
	
	# Reset the tree object id to the database id
	# this will be used below to add edges to the database so
	# we need to be careful and just die if this does not work
	$ind_node->id($node_db_id) || 
	    die "The Tree Object Node ID can not be set\n";


    }

    # Commit changes to database
    $dbh->commit();

    #-----------------------------+
    # ADD EDGES
    #-----------------------------+
    # For the time being these will be stored in parent_id col in the
    # species tree node table. In the future I may want to shift this
    # out to a separate edge table
    print STDERR "\n-----------------------------+\n" 
	if $verbose;
    print STDERR "PROCESSING EDGES\n"
	if $verbose;
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
		    
		    # The following updates the existing record
		    $statement = "UPDATE species_tree_node".
			" SET parent_id = ".
			" '".$anc->id."'".
			" WHERE species_tree_node_id =".
			" '".$ind_node->id."'";
		    
		    print STDERR "$statement\n"
			if $verbose;

		    my $edge_sth = &prepare_sth($dbh,$statement);
		    execute_sth($edge_sth);
		    
		    
		    
		} # End of if ancestor has id 
	    } # End of if the node has an ancestor
	} # End of if node has id
    } # End of for each IndNode

    $dbh->commit();
    
    #-----------------------------+
    # ADD TREE ROOT INFORMATION   |
    #-----------------------------+
    print STDERR "\n-----------------------------+\n" 
	if $verbose;
    print STDERR "PROCESSING ROOT\n"
	if $verbose;
    print STDERR "-----------------------------+\n" 
	if $verbose;

    if ($tree->get_root_node) {
	my $root = $tree->get_root_node;
	# Since all nodes were assigned an id above, using the
	# biosql values, this should return the root id as used
	# in the database
	print "The tree is rooted.\n"
	    if $verbose;
	print "\tRoot:".$root->id."\n"
	    if $verbose;
	# UPDATE tree table
	$statement = "UPDATE species_tree SET root_node_id = '".$root->id."'".
	    " WHERE species_tree_id = '".$tree_db_id."'";
	print "SQL: $statement\n" 
	    if $verbose;
	$sth = prepare_sth($dbh,$statement);
	execute_sth($sth);
    } 
    else {
	print STDERR "The tree is not rooted.\n"
	    if $verbose;
	
	# QUESTION: WHAT TO ENTER FOR ROOT ID FOR AN UNROOTED TREE
	
	# THE FOLLOWING MAY ONLY WORK FOR MYSQL
#	$statement = "UPDATE species_tree SET is_rooted = \'FALSE\'".
#	    " WHERE tree_id = ".$tree_db_id;
#	$sth = prepare_sth($dbh,$statement);
#	execute_sth($sth);
	
    }

    $dbh->commit();
    
    #-----------------------------+
    # ADD VERSION INFORMATION     |
    #-----------------------------+
    # Going to increment version if previous version was not set
    # This is a TODO thing, for now will assume that all trees 
    # have unique name

} # End for for each tree


exit;

#-----------------------------------------------------------+
# SUBFUNCTIONS                                              |
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

__END__

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


=head1 NAME

tr_import_species_tree.pl - Import species tree to RecDB

=head1 VERSION

This documentation refers to program version $Rev: 614 $

=head1 SYNOPSIS

=head2 Usage

    tr_import_species_tree.pl -i infile.nwk -t tree_name

=head2 Required Arguments

    --infile,i        # Path to the species tree file for input

=head1 DESCRIPTION

Imports a species tree into the iPlant tree reconciliation database.

=head1 REQUIRED ARGUMENTS

=over 2

=item -i,--infile

Path of the species tree file.

=back

=head1 OPTIONS

=over 2

=item --format

Format of the species tree used for input. Valid options include 

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

=head2 Typical Use

This is a typcial use case.

=head1 DIAGNOSTICS

=over 2

=item * Expecting input from STDIN

If you see this message, it may indicate that you did not properly specify
the input sequence with -i or --infile flag. 

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head2 Environment

The following options can be set in the user environment.

=over 2

=item TR_USER

User name to connect to the tree reconciliation database.

=item TR_PASSWORD

Password for the tree reconciliation database connection

=item TR_DSN

DSN for the tree reconciliation database connection.

=back

For example in the bash shell this would be done be editing your .bashrc file
to contain:

    export TR_USERNAME=yourname
    export TR_PASS=yourpassword
    export TR_DSN='DBI:mysql:database=iplant_tr;host-localhost'

=head1 DEPENDENCIES

The program is dependent on the following:

* BioPerl

Specifically the TreeIO module. 

* DBI

Module required For connecting to the database.

* DBD::mysql 

The driver for connecting to a mysql database

=head1 BUGS AND LIMITATIONS

Any known bugs and limitations will be listed here.

=head1 REFERENCE

No current manuscript or web site reference for use of this script.

=head1 LICENSE

GNU General Public License, Version 3

L<http://www.gnu.org/licenses/gpl.html>

=head1 AUTHOR

James C. Estill E<lt>JamesEstill at gmail.comE<gt>

=head1 HISTORY

STARTED: 09/21/2010

UPDATED: 04/12/2011

VERSION: $Rev: 614 $

=cut

#-----------------------------------------------------------+
# HISTORY                                                   |
#-----------------------------------------------------------+
#
