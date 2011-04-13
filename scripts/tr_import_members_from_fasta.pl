#!/usr/bin/perl -w
#-----------------------------------------------------------+
#                                                           |
# tr_import_members_from_fasta.pl                           |
#                                                           |
#-----------------------------------------------------------+
#                                                           |
#  AUTHOR: James C. Estill                                  |
# CONTACT: JamesEstill_@_gmail.com                          |
# STARTED: 09/28/2010                                       |
# UPDATED: 04/12/2011                                       |
# VERSION: $Rev: 613 $                                            |
#                                                           |
# DESCRIPTION:                                              |
#  Load the members table with information from a FASTA     |
#  file. If the fasta files are tagged by the               |
#  LocusID_SourceTaxa system, these data can be used to     |
#  update the following fields:                             |
#    * member_id                                            |
#    * stable_id -- as the internal project locus id        |
#    * taxon_id --- as the genbank id                       |
#  When give a directory, will load all of the fasta        |
#  files in the directory and when given a single fasta     |
#  file will only load the fasta file.                      |
#                                                           |
# USAGE:                                                    |
#  tr_import_members_from_fasta.pl -i infile.fasta          |
#  tr_import_members_from_fasta.pl -i indir/                |
#                                                           |
# LICENSE:                                                  |
# Simplified BSD License                                    |
# http://tinyurl.com/iplant-tr-license                      |
#-----------------------------------------------------------+
# To test import:
# ./tr_import_members_from_fasta.pl -i sandbox/ --driver mysql --dbname tr_test --host localhost --verbose
#
# For the full impoart
# ./tr_import_members_from_fasta.pl ../bowers_clusters/clusters/aa_seqs/  --driver mysql --dbname tr_test --host localhost --verbose
#
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
my ($VERSION) = q$Rev: 613 $ =~ /(\d+)/;

# Get command-line arguments, or die with a usage statement
my $in_path;                   # Input path can be a directory or file
                               # or STDIN
my $in_format = "fasta";       # The expected format of input
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
		    "f|format=s"        => \$in_format,
#		    "s|species=s" => \$species_tree_name,
#		    "c|cluster=s" => \$cluster_set_name,
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
	if ($in_format =~ "fasta") {
	    opendir( DIR, $in_dir ) || 
		die "Can't open directory:\n$in_dir"; 
	    @tmp_file_paths = grep /\.fasta$|\.fa$/, readdir DIR ;
	    closedir( DIR );
	}
	
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

    #-----------------------------+
    # ADD DATA TO THE FAMILY      |
    # TABLE                       |
    #-----------------------------+
    #////////////////////////////////////////////
    # ASSUMES THAT THE FAMLIY NAME DOES NOT 
    # ALREADY EXIST IN THE DATATABASE
    #////////////////////////////////////////////
    # Get filename from file name
    my @suffix_list = (".fasta",
		       "_AA.fa",
		       ".fna",
		       ".faa");
    my $family_base_name = basename($in_file,@suffix_list);
    # The following var can be used to further parse the above name if needed
    # but the suffix list should usually do all of the work
    my $family_stable_id = $family_base_name;
    print STDERR "Family:\t".$family_base_name."\n"
	if $verbose;
    my $statement = "INSERT INTO family".
	" (stable_id) ".
	" VALUES".
	" ('".$family_stable_id."')";
    print STDERR "\tSQL: $statement\n" 
	if $verbose;
    my $insert_famid_sth = &prepare_sth($dbh,$statement);
    &execute_sth($insert_famid_sth);

    my $family_id = &last_insert_id($dbh,"family", $driver);
    print STDERR "\tFamily ID:\t$family_id\n"
	if $verbose;

    my $inseq = Bio::SeqIO->new('-file' => "<$in_file",
				'-format' => $in_format);

    # Get some information about the sequence

    while (my $seqin = $inseq->next_seq) {
	my $species_name;
	my $locus_id;
	($locus_id, $species_name) = split (/\_/,$seqin->primary_id());
	my $genbank_id = &taxon_2_gbid( $species_name );


	print STDERR "\t".$seqin->primary_id()."\n"
	    if $verbose;
#	print STDERR "\t\tLocus: ".$locus_id."\n"
#	    if $verbose;
#	print STDERR "\t\tSpecies: ".$species_name."\n"
#	    if $verbose;
#	print STDERR "\t\tGB-ID: ".$genbank_id."\n"
#	    if $verbose;

	    # we can set the species object	
#	print STDERR "\t".$seqin->species;


	# Currently will assume that the stable_id does not
	# already exist in the database, otherwise would

	#-----------------------------+
	# CHECK IF MEMBER IS ALREADY  |
	# IN THE DATABASE             |
	#-----------------------------+
	my $member_id = stable_id_2_member_id ($locus_id);

	#-----------------------------+
	# LOAD INFORMATION TO MEMBERS |
	# TABLE IF NOT ALREADY        |
	# PRESENT                     |
	#-----------------------------+
	unless ($member_id) {
	    my $statement = "INSERT INTO member".
		" ( stable_id,".
		" display_label,".
		" taxon_id)".
		" VALUES (".
		" '".$locus_id."',".
		" '".$locus_id."',".
		" '".$genbank_id."')";
	    print STDERR "\t\tSQL: $statement\n"
		if $verbose;
	    my $insert_member_sth = &prepare_sth($dbh,$statement);
	    &execute_sth($insert_member_sth);
	    # the following should work to set the member_id
	    $member_id = stable_id_2_member_id ($locus_id);
	}
	else {
	    print STDERR "\t\tMember id is ".$member_id."\n"
		if $verbose;
	}

	#-----------------------------+
	# ADD FAMILY MEMMERS TO THE   |
        # FAMILY_MEMBER TABLE         |
	#-----------------------------+
	#///////////////////////////////////////////////////////////
	# TO DO: CHECK THAT MEMBER FAMILY PAIR NOT ALREADY PRESENT
	#///////////////////////////////////////////////////////////
	my $statement = "INSERT INTO family_member ".
	    " ( family_id, member_id )".
	    " VALUES (".
	    " '".$family_id."',".
	    " '".$member_id."')";
	print STDERR "\t\tSQL: $statement \n"
	    if $verbose;
	my $insert_fam_member_sth = &prepare_sth($dbh,$statement);
	&execute_sth($insert_fam_member_sth);
	
	#-----------------------------+
	# ADD SEQUENCE DATA TO THE    |
	# SEQUENCE TABLE              |
	#-----------------------------+
	#///////////////////////////////////////////////////////////
	# TO DO: First check that a sequence record does not exist
	#        for this member_id record
	#///////////////////////////////////////////////////////////

	my $insert_seq_sql = "INSERT INTO sequence".
	    " ( length,".
	    " sequence )".
	    " VALUES (".
	    " '".$seqin->length()."',".
	    " '".$seqin->seq()."')";
	print STDERR "\t\tSQL: ".$insert_seq_sql."\n"
	    if $verbose;
	my $insert_seq_sth = &prepare_sth($dbh,$insert_seq_sql);
	&execute_sth($insert_seq_sth);

	#-----------------------------+
	# ADD THIS SEQ ID TO THE      |
	# MEMBER TABLE                |
	#-----------------------------+
	# Get the squence id 
	# This will be used to update the squence id in the member table
	my $seq_db_id = &last_insert_id($dbh,"sequence", $driver);
	my $update_member_table_sql = "UPDATE member".
	    " SET sequence_id = '".$seq_db_id."'".
	    " WHERE member_id = '".$member_id."'";
	print STDERR "\t\tSQL: $update_member_table_sql\n"
	    if $verbose;
	my $update_member_sth = &prepare_sth($dbh,$update_member_table_sql);
	&execute_sth( $update_member_sth );


    }

    # Get information about the sequence
    my $seq_id
}

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

sub stable_id_2_member_id {
    
    # Get the member_id of a locus in the database given
    # its stable_id
    my $stable_id_search = shift;
    my $member_id_result;

    my $search_sql = "SELECT member_id FROM member".
	" WHERE stable_id = '".$stable_id_search."'";
    print STDERR "\t\tSQL:".$search_sql."\n" 
	if $verbose;
    my $sth = $dbh->prepare($search_sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_arrayref) {
	$member_id_result = @$row[0];
    }

    unless ($member_id_result) {
	$member_id_result = 0;
    }
    
    return $member_id_result;

}

__END__
=head1 NAME

tr_import_members_from_fasta.pl - Import members from fasta file

=head1 VERSION

This documentation refers to program version $Rev: 613 $

=head1 SYNOPSIS

=head2 Usage

    tr_import_members_from_fasta.pl -u UserName -p dbPass -t MyTree
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

This program populates tables in the tree reconcilation database using
input from a FASTA formatted file.

The following tables are populated with this script:

=over

=item family

=item family_member

=item sequence

=item member

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

Taxon IDs are currently not resolved against the database. Currently
a kludge is in place that uses the NCBI taxon IDs for a small
subset of potential species.

=item *

This program expects specific fasta file headers.

The fasta file headers must be set as:

 >locusName_Species

where locusName is the name of the locus/gene and Species
is the name of the species.

Other headers will not work properly.

For example, the following file is in the proper format:

  >POPTR-0010s18130.1_poplar
  MFHTKKPSTMNSHDRPMCVQGDSGLVLTTDPKPRLRWTVELHERFVDAVTQLGGPDKATP
  KTIMRVMGVKGLTLYHLKSHLQKFRLGKQPHKDFNDHSIKDASALDLQRSAASSSGMMSR
  SMNEMQMEVQRRLHEQLEVQRHLQLRTEAQGKYIQSLLEKACQTLAGDQNLASGSYKGMG
  NQGIPGMGAMKEFGTLNFPAFQDLNIYGGDQLDLQHNMDRPSLDGFMPNNDNICLGKKRP
  SPYDGSGKSPLIWPDDLRLQDLGSGPACLEPQDDPFKGDQIQMAPPSMDRGTDLDSISDM
  YEIKPALQGDALDEKKFEASAKLKRPSPRRSPLAAERMSPMINTGAMPQGRNSPFG
  >POPTR-0008s08130.1_poplar
  MFHTKKPSTMNSHDRPMCVQDSGLVLTTDPKPRLRWTVELHERFVDAVAQLGGPDKATPK
  TIMRVMGVKGLTLYHLKSHLQKFRLGKQLHKEFNDHSIKDASALDLQRSAASSSGMISRS
  MNDNSHMIYAIRMQMEVQRRLHEQLEVQRHLQLRTEAQGKYIQSLLEKACQTLAGDQDLA
  SGSYKGIGNQGVPDMGAMKDFGPLNFPPFQDLNIYGSGQLDLLHNMDRPSLDGFMSNNHD
  DICLGKKRTNPYAGSGKSPLIWSDDLRLQDLGSGLSCLGPQDDPLKGDQIQIAPPLMDSG
  TDLDSLSGLYGTKPVHQGDALDEKKLEASAKTERPSPRRAPLAADRMSPMINTGVMPQGR
  NSPFG

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

Started: 09/28/2010

Updated: 04/12/2011

=cut
