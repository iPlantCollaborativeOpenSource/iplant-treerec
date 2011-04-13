#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           |
# tr_index_protein_tree.pl - Index protein trees in TRDB    |
#                                                           |
#-----------------------------------------------------------+
#                                                           |
# CONTACT: JamesEstill_at_gmail.com                         |
# STARTED: 11/30/2010                                       |
# UPDATED: 03/28/2011                                       |
#                                                           |
# DESCRIPTION:                                              | 
#  Index protein trees in the tree reconciliation database. |
#  This will:                                               |
#   1) add left and right index values in the table         |
#       protein_tree_node                                   |
#   2) compute transitive closure path in the table         |
#      protein_tree_node_path                               |
#                                                           |
# LICENSE:                                                  |
#  Simplified BSD License                                   |
#  http://tinyurl.com/iplant-tr-license                     |
#                                                           |
#-----------------------------------------------------------+
# TO TEST:
# Assuming database variables defined in user environment
# ./tr_index_protein_tree.pl --verbose -t 1
#
 
#-----------------------------+
# INCLUDES                    |
#-----------------------------+
use strict;
use DBI;
use Getopt::Long;
use constant LOG_CHUNK => 10000;
# The following needed for printing help
use Pod::Select;               # Print subsections of POD documentation
use Pod::Text;                 # Print POD doc as formatted text file
use IO::Scalar;                # For print_help subfunction
use IO::Pipe;                  # Pipe for STDIN, STDOUT for POD docs
use File::Spec;                # Convert a relative path to an abosolute path

#-----------------------------+
# VARIABLE SCOPE              |
#-----------------------------+
my ($VERSION) = q$Rev: 615 $ =~ /(\d+)/;

my $usrname = $ENV{TR_USERNAME};  # User name to connect to database
my $pass = $ENV{TR_PASSWORD};     # Password to connect to database
my $db = $ENV{TR_DBNAME};         # Database name (ie. tr_rosids)
my $host = $ENV{TR_DBHOST};       # Database host (ie. localhost)
my $dsn = $ENV{TR_DSN};           # DSN for database connection

my $infile;                    # Full path to the input file to parse
my $driver;                    # Database driver (ie. mysql)
my $tree_in_id;                # The id number of the tree to index
                               # For files with multiple trees, this may
                               # be used as a base name to name the trees with
my $statement;                 # Var to hold SQL statement string
#my $sth;                      # Statement handle for SQL statement object
my @trees = ();                # Array holding the names of the trees that will
                               # be indexed
my $verbose;                   # Boolean, but chatty or not
my $tree;                      # This is what H. Lapp used
my $show_help = 0;             # Display help
my $show_man = 0;              # Show the man page via perldoc
my $show_usage = 0;            # Show the basic usage for the program
my $show_version = 0;          # Show the program version

#-----------------------------+
# COMMAND LINE OPTIONS        |
#-----------------------------+
my $ok = GetOptions( "t|tree=s"  => \$tree_in_id, 
                    # DSN
                    "d|dsn=s"    => \$dsn,
		     # ALTERNATIVE TO --dsn
		    "driver=s"   => \$driver,
		    "dbname=s"   => \$db,
		    "host=s"     => \$host,
		     # THE FOLLOWING CAN BE DEFINED IN ENV
                    "u|dbuser=s" => \$usrname,
                    "p|dbpass=s" => \$pass,
                    "verbose"    => \$verbose,
		     # BOOLEANS
		    "version"    => \$show_version,
		    "man"        => \$show_man,
		    "usage"      => \$show_usage,
		    "h|help"     => \$show_help,
		    );

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
    $dbh, "SELECT node_id FROM protein_tree_node WHERE parent_id = ?");  
my $upd_nestedSet  = prepare_sth(
    $dbh, "UPDATE protein_tree_node SET left_index = ?, right_index = ? WHERE node_id = ?");
my $reset_nestedSet = prepare_sth(
    $dbh, "UPDATE protein_tree_node SET left_index = null, right_index = null ".
    "WHERE protein_tree_id =?");
my $sel_trees = 
    "SELECT root_node_id, protein_tree_id FROM protein_tree";

#-----------------------------+
# GET THE TREES TO PROCESS    |
#-----------------------------+
# TODO: Check to see if the tree does exist in the database
#        throw error message if it does not

my @bind_params = ();
if (defined($tree_in_id)) {
#    "SELECT root_node_id, protein_tree_id FROM protein_tree";
    $sel_trees .= " WHERE protein_tree.protein_tree_id = ?";
    push(@bind_params, $tree_in_id);
}

my $sth = prepare_sth($dbh, $sel_trees);
execute_sth($sth, @bind_params);

while(my $row = $sth->fetchrow_arrayref) {
    my ($root_id, $tree_id) = @$row;

    #-----------------------------+
    # NESTED SET VALUES           |
    #-----------------------------+
    print STDERR "Computing nested set values for tree $tree_id ...\n";
    print STDERR "\tresetting existing values\n" 
	if $verbose;

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
    print STDERR "Computing transitive closure for tree $tree_id...\n";
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
        "DELETE FROM protein_tree_node_path WHERE child_node_id IN ("
        ." SELECT node_id FROM protein_tree_node WHERE protein_tree_id = ?)";
    my $zero_sql = 
        "INSERT INTO protein_tree_node_path (child_node_id, parent_node_id, distance)"
        ." SELECT n.node_id, n.node_id, 0 "
	." FROM protein_tree_node n "
	." WHERE n.protein_tree_id = ?";
    my $init_sql = 
        "INSERT INTO protein_tree_node_path (child_node_id, parent_node_id, path, distance)"
        ." SELECT n.node_id, n.parent_id, n.left_index, 1"
        ." FROM protein_tree_node n"
        ." WHERE protein_tree_id = ?";
   # The following CONCAT is a MYSL syntax for string concatenation
    my $path_sql =
        "INSERT INTO protein_tree_node_path (child_node_id, parent_node_id, path, distance)"
        ." SELECT n.node_id, p.parent_node_id,"
        ." CONCAT (p.path,'.',n.left_index), p.distance+1"
        ." FROM protein_tree_node_path p, protein_tree_node n"
        ." WHERE p.child_node_id = n.parent_id"
        ." AND n.protein_tree_id = ?"
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

__END__

=head1 NAME 

tr_index_protein_tree.pl - Index protein trees in TR DB

=head1 VERSION

This documentation refers to tr_index_protein_tree.pl version 1.0

=head1 SYNOPSIS

=head2 Usage

    tr_index_protein_tree.pl -u UserName -p dbPass -t MyTree
                             -d 'DBI:mysql:database=biosql;host=localhost' 
                   
=head2 Required Arguments

        The following options may also be specified in the
        user environment.
        --dsn        # The DSN string the database to connect to
                     # Must conform to:
                     # 'DBI:mysql:database=trdb;host=localhost' 
        --dbuser     # User name for db connection
        --dbpass     # Password for db connection
    ALTERNATIVE TO --dsn:
        --driver     # "mysql", "Pg", "Oracle" (default "mysql")
        --dbname     # Name of database to use
        --host       # optional: host to connect with
    ADDITIONAL OPTIONS:
        --tree       # ID of the tree to inex
                     # Otherwise all protein trees are indexed
        --verbose    # Run the program in verbose mode.
	--version    # Show the program version and exit
	--usage      # Show program usage and exit
        --help       # Print short help message and exit
	--man        # Open full program manual

=head1 DESCRIPTION

This utility will index protein trees in the tree reconciliation database.

Specifically, this will:

=over

=item *

Add left and right index values in the table I<protein_tree_node>

These left and right index values will be incremented across the entire
database, such that everying node in protein_tree_node has a unique
left and right index. This allows for subtree selection queries that
do not need to included a protein tree identifier in the query.

=item *

Compute transitive closure path in the table I<protein_tree_node_path>

These paths list all children nodes for every parent node in the 
protein tree.

=back

=head1 REQUIRED ARGUMENTS

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

=head2 OPTIONS

=over 2

=item -t, --tree

Name of the tree that will be indexed. Otherwise all trees in the
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

Assuming that the database variables are defined in the user environment,
the following should index the protein tree with the id of 10

    ./tr_index_protein_tree.pl --verbose --tree 10

=head1 DIAGNOSTICS

Error messages generated by this program and possible solutions are listed
below.

=over

=item ERROR: Error msg

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

The tr_index_protein_tree.pl program is dependent on the
following Perl modules.

=over

=item DBI - L<http://dbi.perl.org>

The PERL Database Interface (DBI) module allows for connections 
to multiple databases. This implementation of the tree reconciliation
database is limited to MySQL.

=item DBD:MySQL - 
L<http://search.cpan.org/~capttofu/DBD-mysql-4.005/lib/DBD/mysql.pm>

MySQL database driver for DBI module.

=item Getopt::Long - L<http://perldoc.perl.org/Getopt/Long.html>

The Getopt module allows for the passing of command line options
to perl scripts.

=item Bio::Tree - L<http://www.bioperl.org>

The Bio::Tree module is part of the bioperl package.

=back

The MySQL RDBMS is also required.

=head1 BUGS AND LIMITATIONS

=head2 Limiations

The following limiations are known:

=over

=item *

Currently only stable with the MySQL Database driver.

=item *

DSN string must currently be in the form:
DBI:mysql:database=DBNAME;host=DBHOST

such as:
DBI:mysql:database=reconciliation_db;host=localhost

=back

=head2 Bugs

Please report bugs to:
http://pods.iplantcollaborative.org/jira

=head1 SEE ALSO

The program tr_index_protein_tree.pl is a component of a package of
command line programs for reconciled tree managament. For additional 
information see:
L<https://pods.iplantcollaborative.org/wiki/display/iptol/1.0+Architecture>

=head1 LICENSE

Simplified BSD License
http://tinyurl.com/iplant-tr-license

=head1 AUTHORS

James C. Estill E<lt>JamesEstill at gmail.comE<gt>

Also includes subfunctions from:

Hilmar Lapp E<lt>hlapp at gmx.netE<gt>

William Piel E<lt>william.piel at yale.eduE<gt>

=head1 HISTORY

Started: 11/30/2010

Updated: 03/28/2011

=cut
