#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           |
# tr_import_go_assignments.pl - Add GO assignments to TR DB |
#                                                           |
#-----------------------------------------------------------+
#                                                           |
#  AUTHOR: James C. Estill                                  |
# CONTACT: JamesEstill_@_gmail.com                          |
# STARTED: 10/13/2010                                       |
# UPDATED: 04/12/2011                                       |
# VERSION: $Rev: 625 $                                            |
#                                                           |
# DESCRIPTION:                                              |
# Import gene ontology (GO) assignments for each gene in    |
# the tree reconciliation database.                         |
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
use Bio::SeqIO;               # Read and write seq files in different formats
use Cwd;                      # Get the current working directory
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
my ($VERSION) = q$Rev: 625 $ =~ /(\d+)/;

# Get command-line arguments, or die with a usage statement
my $in_path;                   # Input path can be a directory or file
                               # or STDIN
my $seq_count = 0;


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

#-----------------------------+
# COMMAND LINE OPTIONS        |
#-----------------------------+
my $ok = GetOptions(# REQUIRED OPTIONS
		    "i|infile|indir=s"  => \$in_path,
		    # DSN
                    "d|dsn=s"         => \$dsn,
		    # ALTERNATIVE TO --dsn 
		    "driver=s"        => \$driver,
		    "dbname=s"        => \$db,
		    "host=s"          => \$host,
		    # THE FOLLOWING CAN BE DEFINED IN ENV
		    "u|dbuser=s"      => \$usrname,
                    "p|dbpass=s"      => \$pass,
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
	opendir( DIR, $in_dir ) || 
	    die "Can't open directory:\n$in_dir"; 
	@tmp_file_paths = grep /\.tsv$|\.csv$/, readdir DIR ;
	closedir( DIR );
	
	# Append directory to path of 
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
# PROCESS EACH FASTA FILE                                   |
#-----------------------------------------------------------+
# TO DO: SET FAMILY NAME WHEN IMPORTING THESE

foreach my $in_file (@input_files) {

    print STDERR "Processing $in_file\n"
	if $verbose;
    $seq_count++;
    

    open (INFILE, $in_file) ||
	die "Can not open input file $in_file\n";

    my $line=0;
    while (<INFILE>) {
	$line++;
	chomp;
	print STDERR $_."\n"
	    if $verbose;
	my @in_vals = split (/\t/);

	my $in_locus = $in_vals[0];
	my ($locus_id,$species) = split (/\_/,$in_locus);

	my $in_go_id = $in_vals[1];
	my ($in_go_pre,$in_go_number) = split (/\:/,$in_go_id);
	my $in_go_term = $in_vals[3];
	my $in_goslim = $in_vals[4];

	print STDERR "\t".$in_locus." -- ".$in_go_number."\n"
	    if $verbose;
	print STDERR "\t".$locus_id."\n"
	    if $verbose;

	# Get values to load to 
	my $cvterm_id = gonumber_2_cvterm_id($dbh,$in_go_number) ||
	    "NO_VALUE";

	my $member_id = stable_id_2_member_id($dbh,$locus_id) || 
	    "NO_VALUE";
	
	# SKIP TRYING TO WRITE ERRORS TO DATABASE
	# AND WRITE INTPUT VALUES TO STDOUT
	# This should capture values that may not have go terms in the 
	# database or other erros in the database
	if ( $cvterm_id =~ "NO_VALUE") {
	    print STDOUT "# ERROR - CVTERM: LINE $line\n";
	    print STDOUT "# GO - $in_go_number\n";
	    print STDOUT "$_\n";
	    next;
	}
	elsif ( $member_id =~ "NO_VALUE" ) {
	    print STDOUT "# ERROR - MEMBERID: LINE $line\n";
	    print STDOUT "#  LOCUS AS: $locus_id\n";
	    print STDOUT "$_\n";
	    next;
	}

	#-----------------------------+
	# INSERT VALUES TO            |
	# member_attribute            |
	#-----------------------------+
	my $statement = "INSERT INTO member_attribute".
	    " ( member_id, cvterm_id )".
	    " VALUES (".
	    " '".$member_id."',".
	    " '".$cvterm_id."' )";
	print STDERR "\t\tSQL: $statement \n"
	    if $verbose;
	my $insert_mem_atr_sth = &prepare_sth($dbh,$statement);
	&execute_sth($insert_mem_atr_sth);
	
    }

    close (INFILE);

}

exit;

#-----------------------------------------------------------+
# SUBFUNCTIONS
#-----------------------------------------------------------+


sub stable_id_2_member_id {
    
    # Get the member_id of a locus in the database given
    # its stable_id
    my ($dbh, $stable_id_search) = @_;
    my ($sql, $cur, $result, @row);

    my $member_id_result;

    $sql = "SELECT member_id FROM member".
	" WHERE stable_id = '".$stable_id_search."'";

    $cur = $dbh->prepare($sql);
    $cur->execute();
    @row=$cur->fetchrow;
    $result=$row[0];
    $cur->finish();

    return $result;

}


sub gonumber_2_cvterm_id {
    my ($dbh, $go_number) = @_;
    my ($sql, $cur, $result, @row);

    # The following will give the cvterm_id from the database
    # for the GO number (ie GO:0009987)
    $sql = "SELECT cvterm.cvterm_id".
	" FROM cvterm".
	" LEFT JOIN dbxref".
	" ON cvterm.dbxref_id=dbxref.dbxref_id".
	" LEFT JOIN db".
	" ON db.db_id=dbxref.db_id".
	" WHERE db.name = 'GO'".
	" AND dbxref.accession = '".$go_number."'";

    $cur = $dbh->prepare($sql);
    $cur->execute();
    @row=$cur->fetchrow;
    $result=$row[0];
    $cur->finish();
    
    return $result;

}


sub taxon_2_gbid {
    # Convert taxa name to a valid genbank identfier integer
    # returns 0 when name not found
    my $in_taxon = shift;
    
    my %taxa = 
	("cucumber" => "3659",
	 "Arabidopsis" => "3702",
	 "grape" => "29760",
	 "poplar" => "3694",
	 "soybean" => "3847",
	 "papaya" => "3649"
	);
    my $gb_id;
    $gb_id = $taxa{"$in_taxon"} ||
	"unknown";
    return $gb_id;
    
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

tr_import_go_assignments.pl - Add GO assignments to TR DB

=head1 VERSION

This documentation refers to prog_name.pl version $Rev: 625 $

=head1 SYNOPSIS

=head2 Usage

   ./tr_import_go_assignments.pl -i sandbox/annotated_genes_test.tsv 
                                 --driver mysql --dbname tr_test 
                                 --host localhost --verbose
                                 --dbuser NAME --dbpass PASSWORD
                   
=head2 Required Arguments

        --infile     # File containing GO assignments
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

Import gene ontology (GO) assignments for each gene in
the tree reconciliation database. 

=head1 REQUIRED ARGUMENTS

=over

=item -i, --infile

The file containing the GO assignments. This is a tab delimited text 
file.

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

=head2 Example use

The following example would import the go assignments in the file
annotated_genes_test.tsv into the 

   ./tr_import_go_assignments.pl -i sandbox/annotated_genes_test.tsv 
                                 --driver mysql --dbname tr_test 
                                 --host localhost --verbose

=head2 Example Input

The input file is a tab separated text file with unix line endings 
with the following columns of data. 

=over

=item gene

=item GO_term

=item Type

=item descr

=item Go-slim

=item uniprot_protein_score

=item e-value

=item hit_number(of 50)

=item hits/50

=back

This file format is produced by the
program --UNKNOWN, SHELDON DID THIS--.

A example input file is in the following format:

   gene    GO_term Type    descr   GO-slim uniprot_protein score   e-value hit_number(of 50)       hits/50
   AT1G01030_Arabidopsis   GO:0006350      P       "transcription" GO:0006139      Q9MAN1  587     1e-166  9       0.18
   AT1G01030_Arabidopsis   GO:0005634      C       "nucleus"       GO:0005622      Q9MAN1  587     1e-166  9       0.18
   AT1G01030_Arabidopsis   GO:0006355      P       "regulation of transcription, DNA-dependent"    GO:0050789      Q9MAN1  587     1e-166  9       0.18
   AT1G01030_Arabidopsis   GO:0009741      P       "response to brassinosteroid stimulus"  GO:0050896      Q9ZWM9  160     2e-37   1       0.04
   AT1G01030_Arabidopsis   GO:0009873      P       "ethylene mediated signaling pathway"   GO:0050896      Q9ZWM9  160     2e-37   1       0.02
   AT1G01030_Arabidopsis   GO:0003677      F       "DNA binding"   GO:0005488      Q9MAN1  587     1e-166  9       0.18


=head1 DIAGNOSTICS

Error messages generated by this program and possible solutions are listed
below.

=over

=item ERROR: A valid dsn can not be created

A valid dsn string can not be created for connection to the datbase.
This usually occurs when a dsn has not been defined in the command
line options or the variables required to build the dsn have not been
defined. A valid dsn will require the --driver, --dbname, and --host
options be defined at the command line. It is also possible to
define these varialbes in the user environment.

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

=over

=item MySQL

The MySQL RDBMS is also required for the reconciliation database.

=item annot8r??

I believe that Sheldon used the annot8r program with some
post processing to generate the GO assignments.

=back

=head1 BUGS AND LIMITATIONS

=head2 Bugs

Please report bugs to:
http://pods.iplantcollaborative.org/jira

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

=head1 SEE ALSO

The program tr_import_go_assignments.pl
is a component of the iPlant Tree
Reconciliaton suite of utilities. Additional information is available
at:
L<https://pods.iplantcollaborative.org/wiki/display/iptol/1.0+Architecture>

=head1 LICENSE

Simplified BSD License
http://tinyurl.com/iplant-tr-license

=head1 AUTHORS

James C. Estill E<lt>JamesEstill at gmail.comE<gt>

=head1 HISTORY

Started: 10/13/2010

Updated: 04/12/2011

=cut
