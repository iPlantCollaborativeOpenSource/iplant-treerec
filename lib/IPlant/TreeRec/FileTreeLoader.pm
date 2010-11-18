package IPlant::TreeRec::FileTreeLoader;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Bio::TreeIO;
use Class::Std::Utils;
use English qw(-no_match_vars);
use File::Path;
use Perl6::Slurp;
use Readonly;

{
    my %data_dir_of;
    my %filename_extension_of;
    my %tree_format_of;

    ##########################################################################
    # Usage      : $loader = IPlant::TreeRec::FileTreeLoader->new(
    #                  {   data_dir           => $data_dir,
    #                      filename_extension => $extension,
    #                      tree_format        => $format,
    #                  }
    #              );
    #
    # Purpose    : Creates and initializes a new instance of this class.
    #
    # Returns    : The new object.
    #
    # Parameters : data_dir           - the path to the directory containing
    #                                   the data files.
    #              filename_extension - the suffix to append to the gene family
    #                                   name to get the file name.
    #              tree_format        - the format of the tree files.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $data_dir           = $args_ref->{data_dir};
        my $filename_extension = $args_ref->{filename_extension};
        my $tree_format        = $args_ref->{tree_format};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Initialize the properties.
        $data_dir_of{ ident $self }           = $data_dir;
        $filename_extension_of{ ident $self } = $filename_extension;
        $tree_format_of{ ident $self }        = $tree_format;

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
        delete $data_dir_of{ ident $self };
        delete $filename_extension_of{ ident $self };
        delete $tree_format_of{ ident $self };

        return;
    }

    ##########################################################################
    # Usage      : $gene_tree = $loader->load_gene_tree($family_name);
    #
    # Purpose    : Loads the gene tree for the given gene family name.
    #
    # Returns    : The gene tree.
    #
    # Parameters : $family_name - the gene family stable identifier.
    #
    # Throws     : No exceptions.
    sub load_gene_tree {
        my ( $self, $family_name ) = @_;

        # Determine the path to the file.
        my $data_dir = $data_dir_of{ ident $self };
        my $filename = $family_name . $filename_extension_of{ ident $self };
        my $path     = File::Spec->catfile( $data_dir, $filename );

        # Open the file.
        my $input = Bio::TreeIO->new(
            -file   => $path,
            -format => $tree_format_of{ ident $self },
        );

        # Return the first tree from the file.
        return $input->next_tree();
    }
}

1;
__END__
