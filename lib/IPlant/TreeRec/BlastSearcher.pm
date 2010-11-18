package IPlant::TreeRec::BlastSearcher;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

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
    # Returns    : The list of matching gene identifiers.
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

        # Extract the matching gene IDs from the output.
        my @output = split m/ [\r] [\n]? | [\n] /xms, $out;
        return uniq map { ( split ' ' )[1] } @output;
    }
}

1;
__END__
