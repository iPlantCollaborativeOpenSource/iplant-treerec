package IPlant::TreeRec::GoCloud;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );

{
    my %dbh_of;

    ##########################################################################
    # Usage      : $cloud = IPlant::TreeRec::GoCloud->new($dbh);
    #
    # Purpose    : Creates a new word cloud.
    #
    # Returns    : The cloud.
    #
    # Parameters : $dbh - the database handle.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $dbh ) = @_;

        # Create the new object.
        my $self = bless anon_scalar, $class;

        # Set the object properties.
        $dbh_of{ ident $self } = @_;

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
        delete $dbh_of{ ident $self };

        return;
    }

    sub generate_go_cloud {
        my ( $self, $family_name ) = @_;

        # Get the protein tree.
        my $dbh = $dbh_of{ ident $self };
        my $protein_tree = eval {
            $dbh->resultset('ProteinTree')->for_family_name($family_name);
        };
    }
}

1;
__END__
