#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           |
# tr_poplate_family_go_counts.pl - Gene family GO counts    |
#                                                           |
#-----------------------------------------------------------+
#                                                           |
# CONTACT: JamesEstill_at_gmail.com                         |
# STARTED: 02/8/2011                                        |
# UPDATED: 04/13/2011                                       |
# VERSION: $Rev: 632 $                                      |
#                                                           |
# DESCRIPTION:                                              | 
#  Calculates the frequence of GO term occurences for       |
#  each family using information for individual genes       |
#  and loads the data as family attributes.                 |
#                                                           |
# LICENSE:                                                  |
#  Simplified BSD License                                   |
#  http://tinyurl.com/iplant-tr-license                     |
#                                                           |
#-----------------------------------------------------------+

#-----------------------------+
# INCLUDES                    |
#-----------------------------+
use strict;
use DBI;
use Getopt::Long;
# The following needed for printing help
use Pod::Select;               # Print subsections of POD documentation
use Pod::Text;                 # Print POD doc as formatted text file
use IO::Scalar;                # For print_help subfunction
use IO::Pipe;                  # Pipe for STDIN, STDOUT for POD docs
use File::Spec;                # Convert a relative path to an abosolute path

#-----------------------------+
# VARIABLES                   |
#-----------------------------+
my ($VERSION) = q$Rev: 632 $ =~ /(\d+)/;

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

# Vars for command line
my $family_id;                    # The id of the family that is being queried

#-----------------------------+
# COMMAND LINE OPTIONS        |
#-----------------------------+
my $ok = GetOptions(# REQUIRED OPTIONS
		    "tree-id=i"   => \$family_id,
		    # DSN
                    "d|dsn=s"     => \$dsn,
		    # ALTERNATIVE TO --dsn 
		    "driver=s"    => \$driver,
		    "dbname=s"    => \$db,
		    "host=s"      => \$host,
		    # THE FOLLOWING CAN BE DEFINED IN ENV
		    "u|dbuser=s"  => \$usrname,
                    "p|dbpass=s"  => \$pass,
		    "q|quiet"     => \$quiet,
		    "verbose"     => \$verbose,
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
    print STDERR "\nEnter password for the user $usrname\n";
    system('stty', '-echo') == 0 or die "can't turn off echo: $?";
    $pass = <STDIN>;
    system('stty', 'echo') == 0 or die "can't turn on echo: $?";
    chomp $pass;
}


#-----------------------------+
# CONNECT TO THE DATABASE     |
#-----------------------------+
# Commented out while I work on fetching tree structure
my $dbh = &connect_to_db($dsn, $usrname, $pass) ||
    die "Error connecting to database\n";

#-----------------------------------------------------------+
# GET THE IDS FOR THE TYPES OF TERMS                        |
#-----------------------------------------------------------+
my $biol_process_id = get_object_id($dbh,"biological_process");
my $mol_function_id = get_object_id($dbh,"molecular_function");
my $cell_component_id = get_object_id($dbh,"cellular_component");

# Push the ids to an array.
my @go_domains;
$go_domains[0] = $biol_process_id;
$go_domains[1] = $mol_function_id;
$go_domains[2] = $cell_component_id;

# GET IDS FOR THE LIST OF GENE FAMILIES
my $sel_families_sql = "SELECT family_id FROM family";
my $sel_families_sth = $dbh->prepare($sel_families_sql);
$sel_families_sth->execute();

while (my $fam_result = $sel_families_sth->fetchrow_arrayref) {
    
    my $family_id = @$fam_result[0];
    print STDERR "FAMILY: $family_id\n";
    
    # Rank is used in the family_attribute table
    my $rank = 0;
    for my $go_domain (@go_domains) {
	
	my $go_count_sql = "SELECT cvterm.cvterm_id,COUNT(*) as count".
	    " FROM family_member".
	    " LEFT JOIN member ON".
	    " family_member.member_id = member.member_id".
	    " LEFT JOIN member_attribute ON".
	    " member.member_id = member_attribute.member_id".
	    " LEFT JOIN cvterm ON".
	    " member_attribute.cvterm_id = cvterm.cvterm_id".
	    " LEFT JOIN dbxref ON".
	    " cvterm.dbxref_id = dbxref.dbxref_id".
	    " LEFT JOIN db ON".
	    " dbxref.db_id = db.db_id".
	    " LEFT JOIN cvtermpath ON".
	    " cvtermpath.subject_id = cvterm.cvterm_id".
	    " WHERE db.name = \"GO\"".
	    " AND family_member.family_id = ".$family_id.
	    " AND cvtermpath.object_id = \'".$go_domain."\'".
	    " GROUP BY cvterm_id".
	    " ORDER BY count DESC";
	
	print STDERR "SQL:\t $go_count_sql"
	    if $verbose;
	
	my $go_count_sth = $dbh->prepare($go_count_sql);
	$go_count_sth->execute();
	
	my $num_go_terms = 0;
	
	#-----------------------------+
	# UPLOAD COUNT FOR EACH TERM  |
	#-----------------------------+
	while (my $r = $go_count_sth->fetchrow_arrayref) {
	    $rank++;
	    
	    $num_go_terms++;
	    my $go_id = @$r[0];
	    my $go_count = @$r[1];
	    
	    print STDERR "\t".$go_id."\t" if $verbose;
	    print STDERR "COUNT:\t".$go_count."\n" if $verbose;
	    
	    my $insert_go_count_sql = "\t\tINSERT INTO family_attribute".
		" ( family_id, cvterm_id, value, rank )".
		" VALUES ".
		" (".
		" \'".$family_id."\',".
		" \'".$go_id."\',".
		" \'".$go_count."\',".
		" \'".$rank."\'".
		"  )";
	    my $insert_go_count_sth = $dbh->prepare($insert_go_count_sql);
	    $insert_go_count_sth->execute();
	    
	    print STDERR $insert_go_count_sql."\n"
		if $verbose;
	    
	}
	
	
	# The following for testing
#    print STDERR "NUM TERMS:". $num_go_terms."\n";
	
#    print STDERR "\n\n".$go_count_sql."\n\n" if $verbose;
	
	
    } # End of for each go_domain
    
    
} # End of for each family_id


exit;

# NOTE USING THESE RESULTS

#
# 1) Get all values for the family
# SELECT * FROM family_attribute WHERE family_id = 1;

# 2) To get the last value
#SELECT * FROM family_attribute WHERE family_id = 1 AND rank = (SELECT MAX(rank) from family_attribute WHERE family_id = 1);

# 3) To get the count of GO terms for a family
# SELECT MAX(rank) from family_attribute WHERE family_id = 1;

# 4) To get the top ranked biological attribute term or failing that the top 
#    ranked process term.
# SELECT * FROM family_attribute WHERE family_id = 1 and rank = 1;

# 5) The value field is used to hold the count for that family
# 
# To get terms for family level GO clouds


# To get the best GO Terms 
# (biological_attribute > molecular_function>cellular component)
# SELECT * FROM family_attribute WHERE family_id = 1 and RANK = 1;
#-----------------------------------------------------------+
# SUBFUNCTIONS
#-----------------------------------------------------------+


sub get_object_id {
# Get the database if for the parent term being requested

    my ($dbh, $search_name) = @_;
    my ($sql, $cur, $result, @row);
    
    my $member_id_result;
    
    $sql = "SELECT cvterm_id FROM cvterm".
	" WHERE name = \'".$search_name."\'";
    $cur = $dbh->prepare($sql);
    $cur->execute();
    @row=$cur->fetchrow;
    $result=$row[0];
    $cur->finish();
    
    return $result;

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

tr_poplate_family_go_counts.pl - Gene family GO counts 

=head1 VERSION

This documentation refers to
tr_poplate_family_go_counts.pl version $Rev: 632 $

=head1 SYNOPSIS

=head2 Usage

    tr_poplate_family_go_counts.pl -u UserName -p dbPass -t MyTree
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
        --driver     # mysql
        --dbname     # Name of database to use
        --host       # optional: host to connect with

=head1 DESCRIPTION

Calculates the frequence of GO term occurences for
each family using information for individual genes
and loads the data as family attributes.  

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

Example use

    ./prog_name.pl 

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

=head2 Perl Modules

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

=head2 Software

The MySQL RDBMS is also required for the reconciliation database.

=head1 BUGS AND LIMITATIONS

=head2 Bugs

Please report bugs to:
http://pods.iplantcollaborative.org/jira

=head2 Limiations

The following limiations are known:

=over

=item *

This script currently does not check to see if data already
exists in the database for these counts.

=item *

Currently only stable with the MySQL Database driver.

=item *

DSN string must currently be in the form:
DBI:mysql:database=DBNAME;host=DBHOST

such as:
DBI:mysql:database=reconciliation_db;host=localhost

=back

=head1 SEE ALSO

This program is a component of the iPlant Tree
Reconciliaton suite of utilities. Additoinal information is available
at:
L<https://pods.iplantcollaborative.org/wiki/display/iptol/1.0+Architecture>

=head1 LICENSE

Simplified BSD License
http://tinyurl.com/iplant-tr-license

=head1 

=head1 AUTHORS

James C. Estill E<lt>JamesEstill at gmail.comE<gt>

=head1 HISTORY

Started: 02/8/2011 

Updated: 04/13/2011

=cut

