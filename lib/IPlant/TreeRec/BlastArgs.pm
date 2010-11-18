package IPlant::TreeRec::BlastArgs;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

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
    
    ##########################################################################
    # Usage      : $blast_args = IPlant::TreeRec::BlastArgs->_new(
    #                  {   executable => $executable_path,
    #                      sequence   => $sequence,
    #                      database   => $database_file_name,
    #                  }
    #              );
    # 
    # Purpose    : Creates a new set of BLAST arguments.
    #
    # Returns    : The new set of blast arguments.
    #
    # Parameters : executable - the name of the executable file.
    #              sequence   - the query sequence.
    #              database   - the name of the database file.
    #
    # Throws     : No exceptions.
    sub _new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $executable = $args_ref->{executable};
        my $sequence   = $args_ref->{sequence};
        my $database   = $args_ref->{database};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Set the object properties.
        $executable_of{ ident $self } = $executable;
        $sequence_of{ ident $self } = $sequence;
        $database_of{ ident $self } = $database;

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
    #              }
    #
    #              Available sequence types are "nucleotide" and "protein".
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

        # Both the sequence type and sequence are required.
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $sequence_type || !defined $sequence;

        # Get the information we need to create the object.
        my $type_info_ref = $TYPE_INFO_FOR{$sequence_type};
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $type_info_ref;

        # Create the BLAST arguments object.
        return $class->_new(
            {   'executable' => $type_info_ref->{executable},
                'database'   => $type_info_ref->{database},
                'sequence'   => $sequence,
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

        # Extract the names of the executable and database.
        my $exe_name = $executable_of{ ident $self };
        my $db_name  = $database_of{ ident $self };

        # Build the paths to the executable and database.
        my $exe_path = File::Spec->catfile( $exe_dir, $exe_name );
        my $db_path  = File::Spec->catfile( $db_dir, $db_name );

        # Build and return the command.
        return ( $exe_path, '-db', $db_path, '-outfmt', 6 );
    }
}

1;
__END__
