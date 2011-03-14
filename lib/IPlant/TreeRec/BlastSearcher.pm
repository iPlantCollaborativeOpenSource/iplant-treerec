package IPlant::TreeRec::BlastSearcher;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.3';

use Class::Std::Utils;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Path;
use IO::Handle;
use IPC::Run qw(run);
use IPlant::TreeRec::X;
use List::MoreUtils qw(uniq);
use Perl6::Slurp;
use Readonly;

{
    my %executable_dir_of;
    my %database_dir_of;

    ##########################################################################
    # Usage      : $retriever = IPlant::TreeRec::BlastSearcher->new(
    #                  {   executable_dir => $executable_dir,
    #                      database_dir   => $database_dir,
    #                  }
    #              );
    #
    # Purpose    : Creates and initializes a new instance of this class.
    #
    # Returns    : The new object.
    #
    # Parameters : executable_dir     - the path to the directory containing
    #                                   the executable files.
    #              database_dir       - the path to the directory containing
    #                                   the database files.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $executable_dir = $args_ref->{executable_dir};
        my $database_dir   = $args_ref->{database_dir};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Initialize the properties.
        $executable_dir_of{ ident $self } = $executable_dir;
        $database_dir_of{ ident $self }   = $database_dir;

        return $self;
    }

    ##########################################################################
    # Usage      : N/A
    #
    # Purpose    : Cleans up after an instance of this class has gone out of
    #              scope.
    #
    # Returns    : Nothing.
    #
    # Parameters : None.
    #
    # Throws     : No exceptions.
    sub DESTROY {
        my ($self) = @_;

        # Clean up.
        delete $executable_dir_of{ ident $self };
        delete $database_dir_of{ ident $self };

        return;
    }

    ##########################################################################
    # Usage      : @gene_ids = $searcher->search($blast_args);
    #
    # Purpose    : Performs a BLAST search.
    #
    # Returns    : Array of hashes corresponding to BLAST HSPs:
    #              query_id     - ID of the query sequence
    #              gene_id      - Gene ID of the matching sequence
    #              evalue       - Evalue of the match
    #              query_start  - Start of the match on the query sequence
    #              query_end    - End of the match on the query sequence
    #              length       - length of the HSP match
    #
    # Parameters : $blast_args - the blast arguments.
    #
    # Throws     : No exceptions.
    sub search {
        my ( $self, $blast_args ) = @_;

        # Build the command to execute.
        my $exe_dir = $executable_dir_of{ ident $self };
        my $db_dir  = $database_dir_of{ ident $self };
        my @cmd     = $blast_args->build_command( $exe_dir, $db_dir );

        # Execute the command.
        my $sequence = $blast_args->get_sequence();
        my ( $out, $err );
        run \@cmd, \$sequence, \$out, \$err
            or IPlant::TreeRec::IOException->throw( error => $ERRNO );

        # Extract the BLAST results to an array of hashes
        my @rows = split m/ [\r] [\n]? | [\n] /xms, $out;
	my @output;
	for my $row (@rows) {
	    my $blast_result = {};
	    my @cols = split (/\t/,$row);
            my ( $query_id, $gene_id, $evalue, $start, $end ) = @cols;
            $blast_result->{'query_id'} = $self->_strip_species( $query_id );
            $blast_result->{'gene_id'}  = $self->_strip_species( $gene_id );
	    $blast_result->{'evalue'} = $evalue;
	    $blast_result->{'query_start'} = $start;
	    $blast_result->{'query_end'} = $end;
	    $blast_result->{'length'} = abs( int $start - int $end ) + 1;
	    push @output, $blast_result;
	}
	return @output;
    }

    ##########################################################################
    # Usage      : $gene_id = $searcher->_strip_species($gene_id);
    #
    # Purpose    : Removes the species name from the gene identifier.
    #
    # Returns    : The updated gene identifier.
    #
    # Parameters : $gene_id - the gene identifier to update.
    #
    # Throws     : No exceptions.
    sub _strip_species {
        my ( $self, $gene_id ) = @_;
        $gene_id =~ s/ _ [^_]+ \z //xms;
        return $gene_id;
    }
}

1;
__END__
