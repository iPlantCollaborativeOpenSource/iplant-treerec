package IPlant::TreeRec::SpeciesTreeEvents;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );
use Memoize;

memoize( '_get_duplications' );
memoize( '_get_all_duplications' );

{
    my %dbh_of;

    ##########################################################################
    # Usage      : $info = IPlant::TreeRec::GeneTreeEvents->new(
    #                  {   dbh                  => $dbh,
    #                  }
    #              );
    #
    # Purpose    : Creates and initializes a new object instance.
    #
    # Returns    : The new object instance.
    #
    # Parameters : dbh                  - the database handle.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $dbh                  = $args_ref->{dbh};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Initialize the object properties.
        $dbh_of{ ident $self }                  = $dbh;

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

    ##########################################################################
    # Usage      : $events = $info->get_events( $family_name,
    #                  $species_tree_name );
    #
    # Purpose    : Classifies the events on a gene tree.
    #
    # Returns    : The events.
    #
    # Parameters : $family_name       - the gene family name.
    #              $species_tree_name - the gene family tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::ReconciliationNotFoundException
    sub get_all_duplications {
        my ( $self, $species_tree_name ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };
        
        # Obtain the speciation and duplication events.
      	my $duplications = $self->_get_all_duplications( $species_tree_name );

        return $duplications;
    }
    
    ##########################################################################
    # Usage      : $events = $info->get_events( $family_name,
    #                  $species_tree_name );
    #
    # Purpose    : Classifies the events on a gene tree.
    #
    # Returns    : The events.
    #
    # Parameters : $family_name       - the gene family name.
    #              $species_tree_name - the gene family tree.
    #
    # Throws     : IPlant::TreeRec::GeneFamilyNotFoundException
    #              IPlant::TreeRec::TreeNotFoundException
    #              IPlant::TreeRec::ReconciliationNotFoundException
    sub get_duplications {
        my ( $self, $family_name, $species_tree_name ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

         # Get the reconciliation.       
        my $rec = $dbh->resultset('Reconciliation')
        	->for_species_tree_and_family( $species_tree_name, $family_name );
        
        # Obtain the speciation and duplication events.
      	my $duplications = $self->_get_duplications( $rec->id() );

        return $duplications;
    }


    ##########################################################################
    # Usage      : $duplications = $info->_get_duplications($reconciliation_id);
    #
    # Purpose    : Returns all duplication events associated with the
    #              given reconciliation ID.
    #
    # Returns    : A list of the duplication events.
    #
    # Parameters : $reconciliation_id - the ID of the reconciliation to
    #                                   examine.
    #
    # Throws     : No exceptions.
    sub _get_all_duplications {
        my ( $self, $species_tree_name ) = @_;
	
        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the number of duplications.
        my @results = eval { $dbh->resultset('SpeciesDuplications')
            ->search( {}, { 'bind' => [ $species_tree_name ] } ) };
        warn $EVAL_ERROR if $EVAL_ERROR;
  		my%results;
        foreach(@results){
        	if(!defined $_->{_column_data}->{node_id} || $_->{_column_data}->{node_id} eq ""){
        		$results{'00'}=$_->{_column_data}->{count};
        	}
        	else{
       			$results{$_->{_column_data}->{node_id}}=$_->{_column_data}->{count};    
        	}    
        }
        return scalar @results > 0 ? \%results : 0;
    }

    ##########################################################################
    # Usage      : $duplications = $info->_get_duplications($reconciliation_id);
    #
    # Purpose    : Returns all duplication events associated with the
    #              given reconciliation ID.
    #
    # Returns    : A list of the duplication events.
    #
    # Parameters : $reconciliation_id - the ID of the reconciliation to
    #                                   examine.
    #
    # Throws     : No exceptions.
    sub _get_duplications {
        my ( $self, $reconciliation_id ) = @_;
	
        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the number of duplications.
        my @results = eval { $dbh->resultset('SpeciesDuplicationsForFamily')
            ->search( {}, { 'bind' => [ $reconciliation_id ] } ) };
        warn $EVAL_ERROR if $EVAL_ERROR;
  		my%results;
        foreach(@results){
        	if(!defined $_->{_column_data}->{node_id} || $_->{_column_data}->{node_id} eq ""){
        		$results{'00'}=$_->{_column_data}->{count};
        	}
        	else{
       			$results{$_->{_column_data}->{node_id}}=$_->{_column_data}->{count};    
        	}    
		}
        return scalar @results > 0 ? \%results : 0;
    }

}

1;
__END__
