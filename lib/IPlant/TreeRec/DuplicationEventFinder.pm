package IPlant::TreeRec::DuplicationEventFinder;

use warnings;
use strict;

our $version = '0.0.1';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );

{
    my %dbh_of;

    ##########################################################################
    # Usage      : $finder = IPlant::TreeRec::DuplicationEventFinder->new(
    #                  $dbh);
    #
    # Purpose    : Initializes a new duplication event finder with the given
    #              database handle.
    #
    # Returns    : The new duplication event finder.
    #
    # Parameters : $dbh - the database handle.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $dbh ) = @_;

        # Create the new object.
        my $self = bless anon_scalar, $class;

        # Initialize the properties.
        $dbh_of{ ident $self } = $dbh;

        return $self;
    }

    ##########################################################################
    # Usage      : @families = $finder->find_duplication_events(
    #                  $node_id, $edge_selected );
    #
    # Purpose    : Finds duplication events that are located in a specified
    #              place on a species tree.
    #
    # Returns    : The list of gene family names.
    #
    # Parameters : $node_id       - the identifier of the selected node or the
    #                               node that the selected edge leads into.
    #              $edge_selected - true if the edge leading into the node
    #                               with the given ID is selected.
    #
    # Throws     : No exceptions.
    sub find_duplication_events {
        my ( $self, $node_id, $edge_selected ) = @_;

        # Find the duplication events.
        my $dbh = $dbh_of{ ident $self };
        my @family_names = $dbh->resultset('DuplicationSearch')
            ->search( {}, { 'bind' => [ $node_id, !$edge_selected ] } );
        return map { $_->name() } @family_names;
    }
}

1;
__END__
