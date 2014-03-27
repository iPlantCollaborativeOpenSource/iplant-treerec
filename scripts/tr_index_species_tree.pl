#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           |
# tr_index_species_tree.pl - Index species tree in TRDB     |
#                                                           |
#-----------------------------------------------------------+
#                                                           |
# CONTACT: JamesEstill_at_gmail.com                         |
# STARTED: 11/30/2010                                       |
# UPDATED: 11/30/2010                                       |
#                                                           |
# DESCRIPTION:                                              | 
#  Index species trees in the tree reconciliaiotn database. |
#  This will:                                               |
#   1) add left and right index values in the table         |
#       species_tree_node                                   |
#   2) compute transitive closure path in the table         |
#      species_tree_node_path                               |
#                                                           |
# LICENSE:                                                  |
#  Simplified BSD License                                   |
#  http://tinyurl.com/iplant-tr-license                     |
#                                                           |
#-----------------------------------------------------------+
# TO TEST:
# ./tr_index_species_tree.pl --verbose --dbname tr_test --host localhost --driver mysql -u jestill
#
# TO DO:
# - Add help subfunction
 
#-----------------------------+
# INCLUDES                    |
#-----------------------------+
use strict;
use DBI;
use Getopt::Long;
use constant LOG_CHUNK => 10000;

#-----------------------------+
# VARIABLE SCOPE              |
#-----------------------------+
my ($VERSION) = q$Rev: 628 $ =~ /(\d+)/;

my $usrname = $ENV{DBI_USER};  # User name to connect to database
my $pass = $ENV{DBI_PASSWORD}; # Password to connect to database
my $dsn = $ENV{DBI_DSN};       # DSN for database connection
my $infile;                    # Full path to the input file to parse
my $format = 'newick';         # Data format used in infile
my $db;                        # Database name (ie. biosql)
my $host;                      # Database host (ie. localhost)
my $driver;                    # Database driver (ie. mysql)
my $sqldir;                    # Directory that contains the sql to run
                               # to create the tables.
my $quiet = 0;                 # Run the program in quiet mode
                               # will not prompt for command line options
my $tree_name;                 # The name of the tree
                               # For files with multiple trees, this may
                               # be used as a base name to name the trees with
my $statement;                 # Var to hold SQL statement string
#my $sth;                      # Statement handle for SQL statement object
my @trees = ();                # Array holding the names of the trees that will
                               # be exported
my $verbose;                   # Boolean, but chatty or not
my $tree;                      # This is what H. Lapp used
my $show_help = 0;             # Display help
my $show_man = 0;              # Show the man page via perldoc
my $show_usage = 0;            # Show the basic usage for the program
my $show_version = 0;          # Show the program version

#-----------------------------+
# COMMAND LINE OPTIONS        |
#-----------------------------+
my $ok = GetOptions( "t|tree=s"  => \$tree_name, 
                    # DSN
                    "d|dsn=s"    => \$dsn,
		     # ALTERNATIVE TO --dsn
		    "driver=s"   => \$driver,
		    "dbname=s"   => \$db,
		    "host=s"     => \$host,
		     # THE FOLLOWING CAN BE DEFINED IN ENV
                    "u|dbuser=s" => \$usrname,
                    "p|dbpass=s" => \$pass,
		    "s|sqldir=s" => \$sqldir,
		    "q|quiet"    => \$quiet,
                    "verbose"    => \$verbose,
		    "version"    => \$show_version,
		    "man"        => \$show_man,
		    "usage"      => \$show_usage,
		    "h|help"     => \$show_help,
		    );

#-----------------------------+
# SHOW REQUESTED HELP         |
#-----------------------------+

if ($show_usage) {
    print_help("");
}

if ($show_help || (!$ok) ) {
    print_help("full");
}

if ($show_version) {
    print "\n$0:\nVersion: $VERSION\n\n";
    exit;
}

if ($show_man) {
    # User perldoc to generate the man documentation.
    system("perldoc $0");
    exit($ok ? 0 : 2);
}

print "Staring $0 ..\n" if $verbose; 

# A full dsn can be passed at the command line or components
# can be put together
unless ($dsn) {
    # Set default values if none given at command line
    $db = "biosql" unless $db; 
    $host = "localhost" unless $host;
    $driver = "mysql" unless $driver;
    $dsn = "DBI:$driver:database=$db;host=$host";
} else {
    
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
    print "\tDSN:\t$dsn\n";
    print "\tPRE:\t$prefix\n";
    print "\tDRIVER:\t$driver\n";
    print "\tSUF:\t$suffix\n";
    print "\tDB:\t$db\n";
    print "\tHOST:\t$host\n";
}


#-----------------------------+
# GET DB PASSWORD             |
#-----------------------------+
# This prevents the password from being globally visible
# I don't know what happens with this in anything but Linux
# so I may need to get rid of this or modify it 
# if it crashes on other OS's

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

#-----------------------------+
# SQL STATEMENTS              |
#-----------------------------+
# Similar syntax would be used for gene trees
my $sel_children = prepare_sth(
    $dbh, "SELECT species_tree_node_id FROM species_tree_node WHERE parent_id = ?");  
my $upd_nestedSet  = prepare_sth(
    $dbh, "UPDATE species_tree_node SET left_index = ?, right_index = ? WHERE species_tree_node_id = ?");
my $reset_nestedSet = prepare_sth(
    $dbh, "UPDATE species_tree_node SET left_index = null, right_index = null ".
    "WHERE species_tree_id =?");
my $sel_trees = 
    "SELECT species_tree_name, root_node_id, species_tree_id FROM species_tree";

#-----------------------------+
# GET THE TREES TO PROCESS    |
#-----------------------------+
# TODO: Check to see if the tree does exist in the database
#        throw error message if it does not

my @bind_params = ();
if (defined($tree_name)) {
    $sel_trees .= " AND species_tree.species_tree_name = ?";
    push(@bind_params, $tree_name);
}

my $sth = prepare_sth($dbh, $sel_trees);
execute_sth($sth, @bind_params);

while(my $row = $sth->fetchrow_arrayref) {
    my ($tree_name, $root_id, $tree_id) = @$row;

    #-----------------------------+
    # NESTED SET VALUES           |
    #-----------------------------+
    print STDERR "Computing nested set values for tree $tree_name...\n";
    print STDERR "\tresetting existing values\n" if $verbose;

    # we need to reset the values to null first to prevent any
    # possible unique key violations when updating on a tree that has
    # them already

    execute_sth($reset_nestedSet, $tree_id);
    # Jamie added the commit here

    print STDERR "\tcomputing new values:\n" if $verbose;
    # recursively traverse the tree, depth-first, filling in the value
    # along the way
    handle_progress(0) if $verbose; # initialize
    walktree($root_id);
    # Jamie added commit here
    $dbh->commit;

    #-----------------------------+
    # TRANSITIVE CLOSURE VALUES   |
    #-----------------------------+

    handle_progress(LOG_CHUNK, 1) if $verbose; # final tally
    print STDERR "Computing transitive closure for tree $tree_name...\n";
    # transitive closure for the given tree; this will delete existing
    # paths first
    compute_tc($dbh, $tree_id);
    print STDERR "Done.\n";
    $dbh->commit;
}

# End of program
$sth->finish();
$dbh->disconnect();
print "\n$0 has finished.\n";
exit;

#-----------------------------------------------------------+
# SUBFUNCTIONS                                              |
#-----------------------------------------------------------+

sub walktree {
# Taken from tree-precompute    
    my $id = shift;
    my $left = shift || 1;
    my $right = $left+1; # default for leaf

    execute_sth($sel_children,$id);
    
    my @children = ();
    while (my $row = $sel_children->fetchrow_arrayref) {
        push(@children,$row->[0]);
    }
    foreach my $child (@children) {
        $right = walktree($child, $right);
        $right++;
    }
    execute_sth($upd_nestedSet, $left, $right, $id);
    handle_progress(LOG_CHUNK) if $verbose;
    return $right;
}

sub handle_progress{
    my $chunk = shift;
    my $final = shift;
    our $_time = time() if $chunk == 0;
    our $_n = 0 if $chunk == 0;
    our $_last_n = 0 if $chunk == 0;
    return if $chunk == 0;
    $_n++ unless $final;
    if ($final || (($_n-$chunk) >= $_last_n)) {
	my $elapsed = time() - $_time;
        my $fmt = "\t%d done (in %d secs, %4.1f rows/s)\n";
        printf STDERR $fmt, $_n, $elapsed, ($_n-$_last_n)/($elapsed||1);
        $_time = time() if $elapsed;
        $_last_n = $_n;
    }
}


sub compute_tc {
# Taken from tree-precompute
    my $dbh = shift;
    my $tree = shift;
    my $del_sql =
        "DELETE FROM species_tree_node_path WHERE child_node_id IN ("
        ." SELECT species_tree_node_id FROM species_tree_node WHERE species_tree_id = ?)";
    my $zero_sql = 
        "INSERT INTO species_tree_node_path (child_node_id, parent_node_id, distance)"
        ." SELECT n.species_tree_node_id, n.species_tree_node_id, 0 "
	." FROM species_tree_node n "
	." WHERE n.species_tree_id = ?";
    my $init_sql = 
        "INSERT INTO species_tree_node_path (child_node_id, parent_node_id, path, distance)"
        ." SELECT n.species_tree_node_id, n.parent_id, n.left_index, 1"
        ." FROM species_tree_node n"
        ." WHERE species_tree_id = ?";
   # The following CONCAT is a MYSL syntax for string concatenation
    my $path_sql =
        "INSERT INTO species_tree_node_path (child_node_id, parent_node_id, path, distance)"
        ." SELECT n.species_tree_node_id, p.parent_node_id,"
        ." CONCAT (p.path,'.',n.left_index), p.distance+1"
        ." FROM species_tree_node_path p, species_tree_node n"
        ." WHERE p.child_node_id = n.parent_id"
        ." AND n.species_tree_id = ?"
        ." AND p.distance = ?";
    print STDERR "\tdeleting existing transitive closure\n" if $verbose;
    my $sth = prepare_sth($dbh,$del_sql);
    execute_sth($sth, $tree);
    print STDERR "\tcreating zero length paths\n" if $verbose;
    $sth = prepare_sth($dbh,$zero_sql);
    execute_sth($sth,$tree);
    print STDERR "\tcreating paths with length=1\n" if $verbose;
    $sth = prepare_sth($dbh,$init_sql);
    execute_sth($sth,$tree);
    $sth = prepare_sth($dbh,$path_sql);
    my $dist = 1;
    my $rv = 1;
    while ($rv > 0) {
        print STDERR "\textending paths with length=$dist\n" if $verbose;
        $rv = execute_sth($sth, $tree, $dist);
        $dist++;
    }
}

sub end_work {
# Copied from load_itis_taxonomy.pl
    
    my ($dbh, $commit) = @_;
    
    # skip if $dbh not set up yet, or isn't an open connection
    return unless $dbh && $dbh->{Active};
    # end the transaction
    my $rv = $commit ? $dbh->commit() : $dbh->rollback();
    if(!$rv) {
	print STDERR ($commit ? "commit " : "rollback ").
	    "failed: ".$dbh->errstr;
    }
    $dbh->disconnect() unless defined($commit);
    
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
    } elsif ((lc($driver) eq 'pg') || ($driver eq 'PostgreSQL')) {
	my $sql = "SELECT currval('${table_name}_pk_seq')";
	my $stmt = $dbh->prepare_cached($sql);
	my $rv = $stmt->execute;
	die "failed to retrieve last ID generated\n" unless $rv;
	my $row = $stmt->fetchrow_arrayref;
	$stmt->finish;
	return $row->[0];
    } else {
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


sub print_help {

    # Print requested help or exit.
    # Options are to just print the full 
    my ($opt) = @_;

    my $usage = "USAGE:\n". 
	"  phyopt.pl -d 'DBI:mysql:database=biosql;host=localhost'\n". 
	"  -u UserName -p dbPass -t MyTree\n";
    my $args = "REQUIRED ARGUMENTS:\n".
        "  --dsn        # The DSN string the database to connect to\n".
        "               # Must conform to:\n".
        "               # 'DBI:mysql:database=biosql;host=localhost'\n".
	"\n".
	"OPTIONS:\n".
	"  --dbname       # Name of the database to connect to\n".
	"  --host         # Database host\n".
	"  --driver       # Driver for connecting to the database\n".
	"  --dbuser       # Name to log on to the database with\n".
	"  --dbpass       # Password to log on to the database with\n".
	"  --tree         # Name of the tree to optimize\n".
	"  --version      # Show the program version\n".     
	"  --usage        # Show program usage\n".
	"  --help         # Show this help message\n".
	"  --man          # Open full program manual\n".
	"  --verbose      # Run the program with maximum output\n". 
	"  --quiet        # Run program with minimal output\n";
	
    if ($opt =~ "full") {
	print "\n$usage\n\n";
	print "$args\n\n";
    }
    else {
	print "\n$usage\n\n";
    }
    
    exit;
}

#-----------------------------------------------------------+
# The following from the phyopt cmd this is built from      |
# IGNORE FOR NOW
# 11/30/2010
#-----------------------------------------------------------+


=head1 NAME 

tr_index_species_tree.pl - Index species trees in TR DB

=head1 VERSION

This documentation refers to tr_index_species_tree.pl version 0.0

=head1 SYNOPSIS

  USAGE: tr_index_species_tree.pl -u UserName -p dbPass -t MyTree
         -d 'DBI:mysql:database=biosql;host=localhost' 
                   

    REQUIRED ARGUMENTS:
        --dsn        # The DSN string the database to connect to
                     # Must conform to:
                     # 'DBI:mysql:database=biosql;host=localhost' 
        --dbuser     # User name to connect with
        --dbpass     # Password to connect with
    ALTERNATIVE TO --dsn:
        --driver     # "mysql", "Pg", "Oracle" (default "mysql")
        --dbname     # Name of database to use
        --host       # optional: host to connect with
    ADDITIONAL OPTIONS:
        --tree       # Name of the tree to optimize.
                     # Otherwise the entire db is optimized.
        --quiet      # Run the program in quiet mode.
        --verbose    # Run the program in verbose mode.
    ADDITIONAL INFORMATION:
	--version    # Show the program version     
	--usage      # Show program usage
        --help       # Print short help message
	--man        # Open full program manual

=head1 DESCRIPTION

The phyopt program will optimize trees in a PhyloDB database by computing
transitive closure paths as well as the left and right index values for
the nested set indexes.

=head1 COMMAND LINE ARGUMENTS

=head2 Required Arguments

=over

=item -d, --dsn

The DSN of the database to connect to; default is the value in the
environment variable DBI_DSN. If DBI_DSN has not been defined and
the string is not passed to the command line, the dsn will be 
constructed from --driver, --dbname, --host

DSN must be in the form:

DBI:mysql:database=biosql;host=localhost

=item -u, --dbuser

The user name to connect with; default is the value in the environment
variable DBI_USER.

This user must have permission to create databases.

=item -p, --dbpass

The password to connect with; default is the value in the environment
variable DBI_PASSWORD. If this is not provided at the command line
the user is prompted.

=back

=head2 Alternative to --dsn

An alternative to passing the full dsn at the command line is to
provide the components separately.

=over 2

=item --host

The database host to connect to; default is localhost.

=item --dbname

The database name to connect to; default is biosql.

=item --driver

The database driver to connect with; default is mysql.
Options other then mysql are currently not supported.

=back

=head2 Additional Options

=over 2

=item -t, --tree

Name of the tree that will be optimized. Otherwise all trees in the
database will be optimized.

=item -q, --quiet

Run the program in quiet mode.

=item --verbose

Execute the program in verbose mode.

=back

=head2 Additional Information

=over 2

=item --version

Show the program version.   

=item --usage      

Show program usage statement.

=item --help

Show a short help message.

=item --man

Show the full program manual.

=back

=head1 EXAMPLES

B<Optimize a single tree>

The following command options would optimize the tree named MyTree in the
biosql database.

    phyopt.pl -d 'DBI:mysql:database=biosql;host=localhost'
              -u name -p password -t MyTree

B<Optimize entire database>

The following commmand options would optimize all of the individual
trees in the database named Angio.

    phyopt.pl -d 'DBI:mysql:database=Angio;host=localhost'
              -u name -p password

This could also be done by passing the individual components for
connecting to the database.

    phyopt.pl --driver mysql --database Angio --host localhost
              -u name -p password

=head1 DIAGNOSTICS

The error messages below are followed by descriptions of the error
and possible solutions.

=head1 CONFIGURATION AND ENVIRONMENT

Many of the options passed at the command line can be set as 
options in the user's environment. 

=over 2

=item DBI_USER

User name to connect to the database.

=item DBI_PASSWORD

Password for the database connection

=item DBI_DSN

DSN for database connection.

=back

For example in the bash shell this would be done be editing your .bashrc file
to contain:

    export DBI_USER=yourname
    export DBI_PASS=yourpassword
    export DBI_DSN='DBI:mysql:database=biosql;host-localhost'

=head1 DEPENDENCIES

The phyimport.pl program is dependent on the following Perl modules:

=over2

=item DBI - L<http://dbi.perl.org>

The PERL Database Interface (DBI) module allows for connections 
to multiple databases.

=item DBD:MySQL - 
L<http://search.cpan.org/~capttofu/DBD-mysql-4.005/lib/DBD/mysql.pm>

MySQL database driver for DBI module.

=item DBD:Pg -
L<http://search.cpan.org/~rudy/DBD-Pg-1.32/Pg.pm>

PostgreSQL database driver for the DBI module.

=item Getopt::Long - L<http://perldoc.perl.org/Getopt/Long.html>

The Getopt module allows for the passing of command line options
to perl scripts.

=item Bio::Tree - L<http://www.bioperl.org>

The Bio::Tree module is part of the bioperl package.

=back

A RDBMS is also required. This can be one of:

=over 2

=item MySQL - L<http://www.mysql.com>

=item PostgreSQL - L<http://www.postgresql.org>

=back

=head1 BUGS AND LIMITATIONS

Known limitations:

=over2

=item *
Currently only stable with the MySQL Database driver.

=item *
DSN string must currently be in the form:
DBI:mysql:database=biosql;host=localhost

=back

Please report additional problems to 
James Estill E<lt>JamesEstill at gmail.comE<gt>

=head1 SEE ALSO

The program phyinit.pl is a component of a package of comand line programs
for PhyloDB management. Additional programs include:

=over

=item phyinit.pl

Initialize a PhyloDB database.

=item phyimport.pl

Import common phylogenetic file formats.

=item phyexport.pl

Export tree data in PhyloDB to common file formats.

=item phyqry.pl

Return a standard report of information for a given tree.

=item phymod.pl

Modify an existing phylogenetic database by deleting, adding or
copying branches.

=back

=head1 LICENSE

This file is part of BioSQL.

BioSQL is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

BioSQL is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with BioSQL. If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHORS

James C. Estill E<lt>JamesEstill at gmail.comE<gt>

Hilmar Lapp E<lt>hlapp at gmx.netE<gt>

William Piel E<lt>william.piel at yale.eduE<gt>

=head1 HISTORY

Started: 07/04/2007

Updated: 08/19/2007

=cut
