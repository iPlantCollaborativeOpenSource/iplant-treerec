package IPlant::TreeRec::BlastArgs;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );
use File::Spec;
use JSON qw();
use Readonly;

# Parameter values for supported sequence types.
Readonly my %TYPE_INFO_FOR => (
    nucleotide => {
        executable => 'tblastx',
        database   => 'all_DNA.fa',
    },
    protein => {
        executable => 'blastp',
        database   => 'all_AA.fa',
    },
);

{
    my %executable_of;
    my %sequence_of;
    my %database_of;
    my %evalue_of;
    my %max_num_seqs_of;

    ##########################################################################
    # Usage      : $blast_args = IPlant::TreeRec::BlastArgs->_new(
    #                  {   executable    => $executable_path,
    #                      sequence      => $sequence,
    #                      database      => $database_file_name,
    #                      evalue        => $evalue,
    #                      max_num_seqs  => $max_num_seqs,
    #                  }
    #              );
    # 
    # Purpose    : Creates a new set of BLAST arguments.
    #
    # Returns    : The new set of blast arguments.
    #
    # Parameters : executable    - the name of the executable file.
    #              sequence      - the query sequence.
    #              database      - the name of the database file.
    #              evalue        - the evalue threshold.
    #              max_num_seqs  - maximum number of sequences to return.
    #
    # Throws     : No exceptions.
    sub _new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $executable    = $args_ref->{executable};
        my $sequence      = $args_ref->{sequence};
        my $database      = $args_ref->{database};
	my $evalue        = $args_ref->{evalue};
	my $max_num_seqs  = $args_ref->{max_num_seqs};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Set the object properties.
        $executable_of{ ident $self } = $executable;
        $sequence_of{ ident $self } = $sequence;
        $database_of{ ident $self } = $database;
        $evalue_of{ ident $self } = $evalue;
        $max_num_seqs_of{ ident $self } =  $max_num_seqs;

        return $self;
    }

    ##########################################################################
    # Usage      : $blast_args = IPlant::TreeRec::BlastArgs->from_json($json);
    #
    # Purpose    : Creates a BLAST arguments object from a JSON string in the
    #              format:
    #
    #              {   "sequence":     <sequence>,
    #                  "sequenceType": <sequenceType>,
    #                  "evalue":       <evalue>,
    #                  "maxNumSeqs":   <maxNumSeqs>,
    #              }
    #
    #              Available sequence types are "nucleotide" and "protein".
    #              The type of sequence will be guessed at when not provided.
    #              The evalue is float (ie. 0.00001) or sci notation (ie. 1E-5)
    #              that represents the maximum threshold e-value for reporting
    #              matches in the BLAST database. The evalue defaults to 
    #              0.01 if not defined.
    #              The maxNumSeqs is an integer representing the maximum number
    #              of sequences to return from the BLAST search. The default 
    #              value of maxNumSeqs is 200.
    #              
    # Returns    : The new BLAST arguments object.
    #
    # Parameters : $json - the JSON string.
    #
    # Throws     : No exceptions.
    sub from_json {
        my ( $class, $json ) = @_;

        # Extract the arguments from the JSON.
        my $json_ref      = JSON->new->decode($json);
        my $sequence_type = $json_ref->{'sequenceType'};
        my $sequence      = $json_ref->{'sequence'};
        my $evalue        = $json_ref->{'evalue'};
        my $max_num_seqs  = $json_ref->{'maxNumSeqs'};

        # The sequence is required
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $sequence;

	# Determine the type of sequence if not defined.
	if (!defined $sequence_type) {
            $sequence_type = _determine_sequence_type($sequence);
	}

	# Set default values for evalue and maxNumSeqs.
	$max_num_seqs = '200' if !defined $max_num_seqs;
        $evalue = '0.01' if !defined $evalue;

        # Get the information we need to create the object.
        my $type_info_ref = $TYPE_INFO_FOR{$sequence_type};
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $type_info_ref;

        # Create the BLAST arguments object.
        return $class->_new(
            {   'executable'   => $type_info_ref->{executable},
                'database'     => $type_info_ref->{database},
                'sequence'     => $sequence,
                'evalue'       => $evalue,
                'max_num_seqs' => $max_num_seqs,
            }
        );
    }

    ##########################################################################
    # Usage      : $sequence = $blast_args->get_sequence();
    #
    # Purpose    : Gets the sequence.
    #
    # Returns    : The sequence.
    #
    # Parameters : None.
    #
    # Throws     : No exceptions.
    sub get_sequence {
        my ($self) = @_;
        return $sequence_of{ ident $self };
    }

    ##########################################################################
    # Usage      : @command = $blast_args->build_command( $exe_dir, $db_dir );
    #
    # Purpose    : Builds the command to execute in order to perform the BLAST
    #              search.
    #
    # Returns    : The command.
    #
    # Parameters : $exe_dir - the path to the executable file directory.
    #              $db_dir  - the path to the database file directory.
    #
    # Throws     : No exceptions.
    sub build_command {
        my ( $self, $exe_dir, $db_dir ) = @_;

        # Extract the names of the executable and database
     	# and evalue.
        my $exe_name = $executable_of{ ident $self };
        my $db_name  = $database_of{ ident $self };
	my $evalue   = $evalue_of{ident $self };
	my $max_num_seqs = $max_num_seqs_of{ident $self };

	# Evalue and max number of seqs will have default values.

        # Build the paths to the executable and database.
        my $exe_path = File::Spec->catfile( $exe_dir, $exe_name );
        my $db_path  = File::Spec->catfile( $db_dir, $db_name );

        # Build and return the command.
        return ( $exe_path, '-db', $db_path, '-evalue', $evalue,
		 '-max_target_seqs', $max_num_seqs,
		 '-outfmt', "6 qseqid sseqid evalue qstart qend" );
    }
}

##########################################################################
# Usage      : $sequence_type = _determine_sequence_type($sequence);
#
# Purpose    : Determines the type of the given sequence.  The sequence
#              type is assumed to be 'nucleotide' unless we can find a
#              character that doesn't belong in a nucelotide sequence.
#
# Returns    : The sequence type ('nucleotide' or 'protein');
#
# Parameters : $sequence - the sequence to categorize.
#
# Throws     : No exceptions.
sub _determine_sequence_type {
    my ($sequence) = @_;
    my @lines = split m/ [\r][\n]? | [\n] /ixms, $sequence;

    # Search for sequence lines that do not contain only nucleotide bases.
    LINE:
    for my $line (@lines) {
        next LINE if $line =~ m/ \A > /xms;
        if ( $line !~ m/ \A [ACTG]* \z /xms ) {
            return 'protein';
        }
    }
    return 'nucleotide';
}

1;
__END__
