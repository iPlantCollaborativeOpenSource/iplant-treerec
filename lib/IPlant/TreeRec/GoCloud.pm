package IPlant::TreeRec::GoCloud;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.2';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );
use HTML::TagCloud;
use Readonly;

{
    my %dbh_of;
    my %go_categories_of;
    my %cloud_levels_of;
    my %location_of;

    ##########################################################################
    # Usage      : $cloud = IPlant::TreeRec::GoCloud->new(
    #                  {   'dbh'           => $dbh,
    #                      'go_categories' => \@categories,
    #                      'cloud_levels'  => $levels,
    #                      'location'      => $location,
    #                  }
    #              );
    #
    # Purpose    : Creates a new word cloud.
    #
    # Returns    : The cloud.
    #
    # Parameters : dbh           - the database handle.
    #              go_categories - the list of GO term categories.
    #              cloud_levels  - the number of levels in generated clouds.
    #              location      - the base URL for this service.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $dbh               = $args_ref->{dbh};
        my $go_categories_ref = $args_ref->{go_categories};
        my $cloud_levels      = $args_ref->{cloud_levels};
        my $location          = $args_ref->{location};

        # Create the new object.
        my $self = bless anon_scalar, $class;

        # Set the object properties.
        $dbh_of{ ident $self }           = $dbh;
        $go_categories_of{ ident $self } = $go_categories_ref;
        $cloud_levels_of{ ident $self }  = $cloud_levels;
        $location_of{ ident $self }      = $location;

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
        delete $go_categories_of{ ident $self };
        delete $cloud_levels_of{ ident $self };
        delete $location_of{ ident $self };

        return;
    }

    ##########################################################################
    # Usage      : $cloud = $cloud_generator->generate_go_cloud($family_name);
    #
    # Purpose    : Generates the GO term cloud for the gene family with the
    #              given name.
    #
    # Returns    : The GO term cloud.
    #
    # Parameters : $family_name - the name of the gene family.
    #
    # Throws     : No exceptions.
    sub generate_go_cloud {
        my ( $self, $family_name ) = @_;

        # Get the protein tree identifier.
        my $dbh          = $dbh_of{ ident $self };
        my $protein_tree = eval {
            $dbh->resultset('ProteinTree')->for_family_name($family_name);
        };
        return if !defined $protein_tree;
        my $protein_tree_id = $protein_tree->id();

        # Generate the GO cloud.
        my $go_categories_ref = $go_categories_of{ ident $self };
        my $cloud             = q{};
        for my $go_category ( @{$go_categories_ref} ) {
            my $partial_cloud
                = $self->_go_cloud_for_category( $protein_tree_id,
                $go_category );
            $cloud .= "<div class='$go_category'>$partial_cloud</div>";
        }

        return $cloud;
    }

    ##########################################################################
    # Usage      : $cloud = $cloud_generator->_go_cloud_for_category(
    #                  $protein_tree_id, $go_category );
    #
    # Purpose    : Generates the partial GO cloud for the given protein tree
    #              ID and GO category.
    #
    # Returns    : The HTML for the partial GO cloud.
    #
    # Parameters : $protein_tree_id - the protein tree identifier.
    #              $go_category     - the GO term category.
    #
    # Throws     : No exceptions.
    sub _go_cloud_for_category {
        my ( $self, $protein_tree_id, $go_category ) = @_;

        # Get the GO category ID.
        my $category_id = $self->_get_go_category_id($go_category);

        # Get the list of GO terms for the category.
        my $dbh   = $dbh_of{ ident $self };
        my @terms = $dbh->resultset('GoTermsForFamilyAndCategory')
            ->search( {}, { 'bind' => [ $category_id, $protein_tree_id ] } );

        # Generate the GO cloud.
        my $levels = $cloud_levels_of{ ident $self };
        my $cloud  = HTML::TagCloud->new(
            levels                    => $levels,
            distinguish_adjacent_tags => 1
        );
        for my $term (@terms) {
            my $name = $term->go_term();
            my $count = $term->count();
            $cloud->add_static( "$name ($count)", $count );
        }

        return $cloud->html();
    }

    ##########################################################################
    # Usage      : $cvterm_id
    #                  = $cloud_generator->_get_go_category_id($category);
    #
    # Purpose    : Get the cvterm ID for the GO category with the given name.
    #
    # Returns    : The ID.
    #
    # Parameters : $category - the name of the GO category.
    #
    # Throws     : No exceptions.
    sub _get_go_category_id {
        my ( $self, $category ) = @_;

        # Get the database handle.
        my $dbh = $dbh_of{ ident $self };

        # Get the cvterm for the GO category.
        my $cvterm
            = $dbh->resultset('Cvterm')->find( { 'name' => $category } );
        return if !defined $cvterm;

        return $cvterm->id();
    }
}

1;
__END__
