#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           |
# tr_import_go_transitive_closure.pl - Populates cvtermpath |
#                                                           |
#-----------------------------------------------------------+
#                                                           |
#  AUTHOR: James C. Estill                                  |
# CONTACT: JamesEstill_@_gmail.com                          |
# STARTED: 01/24/2011                                       |
# UPDATED: 04/12/2011                                       |
# VERSION: $Rev: 638 $                                      |
#                                                           |
# DESCRIPTION:                                              |
#                                                           |
# Imports the transitive closure relations for the gene     |
# ontology (GO) terms. This assumes that the GO terms have  |
# already been loaded into the database.                    |
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
my ($VERSION) = q$Rev: 638 $ =~ /(\d+)/;

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


open (INFILE, $in_path) ||
    die "Can not open input file $in_path\n";

my $line_num =0;
while (<INFILE>) {
    $line_num++;
    # skip the first line (header line)
    next if $line_num == 1;
    chomp;
    print STDERR $_."\n"
	if $verbose;
    my @in_vals = split (/\t/);
    
    my $in_tagged_subject = $in_vals[0];
    my ($subject_term_tag,$subject) = split (/\:/,$in_tagged_subject);
    
    my $in_tagged_relation = $in_vals[1];
    my ($relation_term_tag,$relation) = split (/\:/,$in_tagged_relation);

    my $in_tagged_object = $in_vals[2];
    my ($object_term_tag,$object) = split (/\:/,$in_tagged_object);

    my $provenance = $in_vals[3];

    my $xp = $in_vals[4];

    my $redundancy = $in_vals[5];

    #-----------------------------+
    # TRANSLATE GO TERM IDS AND   |
    # RELATIONSHIP ID TO DB       |
    # VALUES                      |
    #-----------------------------+
    my $db_object_id;
    my $db_subject_id;
    my $db_rel_id;

    print STDERR "\t".$subject."--".$relation."--".$object."\n"
	if $verbose;
    
    # Get values to load to the database
    $db_object_id = gonumber_2_cvterm_id($dbh,$object) ||
	"NO_VALUE";
    print STDERR "\tDB OBJECT ID:\t".$db_object_id."\n"
	if $verbose;

    $db_subject_id = gonumber_2_cvterm_id($dbh,$subject) ||
	"NO_VALUE";
    print STDERR "\tDB SUBJECT ID:\t".$db_subject_id."\n"
	if $verbose;
    
    # The following will only work on the GO ontology uses
    # is_a since we are not selecting by database
    $db_rel_id = gorel_2_cvterm_id ($dbh,$relation);
    print STDERR "\tDB RELATION ID:\t".$db_rel_id."\n"
	if $verbose;
    

    #-----------------------------+
    # INSERT VALUES TO            |
    # cvtermpath                  |
    #-----------------------------+
    # First need to check that the id values were found in the database
    # Currently not populating pathdistance
    if ( $db_object_id && $db_subject_id && $db_rel_id ) {

	my $insert_rel_sql = "INSERT INTO cvtermpath".
	    " ( type_id, subject_id, object_id )".
	    " VALUES (".
	    " '".$db_rel_id."',".
	    " '".$db_subject_id."',".
	    " '".$db_object_id."' )";
	print STDERR "\t\tSQL: $insert_rel_sql \n"
	    if $verbose;
	my $insert_rel_sth = &prepare_sth($dbh,$insert_rel_sql);
	&execute_sth($insert_rel_sth)
	    unless $do_test;
	
    }
    else {
	print STDOUT "# TERM NOT FOUND. INFILE LINE $line_num\n";
	print STDOUT "GO TERM NOT FOUND FOR:  ".$object."\n"
	    if !$db_object_id;
	print STDOUT "GO TERM NOT FOUND FOR:  ".$subject."\n"
	    if !$db_subject_id;
	print STDOUT "GO TERM NOT FOUND FOR:  ".$relation."\n"
	    if !$db_rel_id;
    }


    
}

close (INFILE);


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

# Convert the GO relationshiop to the cvterm value
sub gorel_2_cvterm_id {
    my ($dbh, $rel_term) = @_;
    my ($sql, $cur, $result, @row);

    # The following will give the cvterm_id from the relationship
    # this should work for multiple ontologies since these ontologies
    # share the values used to set relationship types
    $sql = "SELECT cvterm_id".
	" FROM cvterm".
	" WHERE".
	" cvterm.name = \'".$rel_term."\'";

    # This could be narrowed by searching under OBO_REL for the db name

    print STDERR "\tSQL:\t".$sql."\n" 
	if $verbose;

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

tr_import_members_from_fasta.pl - Import members from fasta file

=head1 VERSION

This documentation refers to program version $Rev: 638 $

=head1 SYNOPSIS

=head2 Usage

    tr_import_go_transitive_closure.pl.pl -u UserName 
                 -p dbPass -i tc_file.txt
                 -d 'DBI:mysql:database=biosql;host=localhost' 
                   
=head2 Required Arguments

        The following options may also be specified in the
        user environment.
        -i           # The precomputed transitive closure file
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

Imports the transitive closure relations for the gene ontology (GO)
terms. This assumes that the GO terms have already been loaded into 
the database. This populates the table cvtermpath in the tree 
reconciliation database.

=head1 REQUIRED ARGUMENTS

=over

=item i, --infile

The file containing the precomputed transitive closure values for the
GO terms.

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

=head1 OPTIONS

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

The following example use of the program would import the transitive 
closures contained in the file tc_file.txt into the database
names tree_rec.

    tr_import_go_transitive_closure.pl.pl -u UserName 
                 -p dbPass -i tc_file.txt
                 -d 'DBI:mysql:database=tree_rec;host=localhost' 

=head2 Example Input File

The input file should be a tab deliminted text file with unix line endings.
This should be simlar to the following format:

 subject relation        object  provenance      xp      redundancy
 GO:0000001      OBO_REL:is_a    GO:0048311      asserted        link    
 GO:0000001      OBO_REL:is_a    GO:0048308      asserted        link    
 GO:0000001      OBO_REL:is_a    GO:0051179      implied link    
 GO:0000001      OBO_REL:is_a    GO:0051646      implied link    
 GO:0000001      OBO_REL:is_a    GO:0016043      implied link    
 GO:0000001      OBO_REL:is_a    GO:0008150      implied link    
 GO:0000001      OBO_REL:is_a    GO:0051641      implied link    
 GO:0000001      OBO_REL:is_a    GO:0007005      implied link    
 GO:0000001      OBO_REL:is_a    GO:0009987      implied link    
 GO:0000001      OBO_REL:is_a    GO:0006996      implied link    
 GO:0000001      OBO_REL:is_a    GO:0051640      implied link    
 GO:0000002      OBO_REL:is_a    GO:0007005      asserted        link    

Precomputed values are discussed for GO terms at:
L<http://wiki.geneontology.org/index.php/Transitive_closure>
and precomputed files for GO terms are available from
L<http://www.geneontology.org/scratch/transitive_closure/>

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

=head2 Precomputed Files

This program requires a precomputed transitive closure file for
input.
Precomputed values are discussed for GO terms at:
L<http://wiki.geneontology.org/index.php/Transitive_closure>
and precomputed files for GO terms are available from
L<http://www.geneontology.org/scratch/transitive_closure/>

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

=head1 BUGS AND LIMITATIONS

=head2 Bugs

Please report bugs to:
http://pods.iplantcollaborative.org/jira

=head2 Limitations

Currently the tree_reconciliation database is limited to the MySQL RDBMS.

=head1 SEE ALSO

The program prog_name.pl is a component of the iPlant Tree
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

Started: 01/24/2011

Updated: 04/12/2011

=cut
