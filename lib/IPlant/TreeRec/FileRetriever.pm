package IPlant::TreeRec::FileRetriever;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Class::Std::Utils;
use English qw(-no_match_vars);
use File::Path;
use IPlant::TreeRec::Utils qw(camel_case_phrase);
use IPlant::TreeRec::X;
use Perl6::Slurp;
use Readonly;

# Information for the various types of files we can retrieve.
Readonly my %INFO_FOR => (
    'fat-tree' => {
        filename_suffix => '_reconciled.nhx',
        content_type    => 'text/plain',
        file_format     => 'NEWICK',
    },
    'fat-tree-image' => {
        filename_suffix => '_fattree.nhx.gif',
        content_type    => 'image/gif',
        file_format     => 'IMAGE',
    },
    'gene-tree' => {
        filename_suffix => '_genetree.nhx',
        content_type    => 'text/plain',
        file_format     => 'NEWICK',
    },
    'gene-tree-image' => {
        filename_suffix => '_genetree.nhx.png',
        content_type    => 'image/png',
        file_format     => 'IMAGE',
    },
    'amino-acid-sequence' => {
        filename_suffix => '_AA.fa',
        content_type    => 'text/plain',
        file_format     => 'FASTA',
    },
    'amino-acid-multiple-sequence-alignment' => {
        filename_suffix => '_AA.mfa',
        content_type    => 'text/plain',
        file_format     => 'FASTA',
    },
    'dna-sequence' => {
        filename_suffix => '_DNA.fa',
        content_type    => 'text/plain',
        file_format     => 'FASTA',
    },
    'dna-multiple-sequence-alignment' => {
        filename_suffix => '_DNA.mfa',
        content_type    => 'text/plain',
        file_format     => 'FASTA',
    },
    'species-tree-image' => {
        filename     => 'species_tree.png',
        content_type => 'image/png',
        file_format  => 'IMAGE',
    },
    'species-tree' => {
        filename     => 'species_tree.nwk',
        content_type => 'text/plain',
        file_format  => 'NEWICK',
    },
);

{
    my %data_dir_of;

    ##########################################################################
    # Usage      : $retriever = IPlant::TreeRec::FileRetriever->new(
    #                  {   data_dir           => $data_dir,
    #                  }
    #              );
    #
    # Purpose    : Creates and initializes a new instance of this class.
    #
    # Returns    : The new object.
    #
    # Parameters : data_dir           - the path to the directory containing
    #                                   the data files.
    #
    # Throws     : No exceptions.
    sub new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $data_dir = $args_ref->{data_dir};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Initialize the properties.
        $data_dir_of{ ident $self } = $data_dir;

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

        return;
    }

    ##########################################################################
    # Usage      : $file_info_ref = $retriever->load_file( $type, $prefix );
    #
    # Purpose    : Loads a file of the given type and returns information
    #              about the file.
    #
    # Returns    : The file information in the form of a hash reference
    #              containing the file name, MIME content type and the file
    #              contents.
    #
    # Parameters : $type   - the type of file being retrieved.
    #              $prefix - the file name prefix (optional);
    #
    # Throws     : No exceptions.
    sub load_file {
        my ( $self, $type, $prefix ) = @_;

        # Use an empty prefix if one wasn't provided.
        if ( !defined $prefix ) {
            $prefix = "";
        }

        # Get the file type info.
        my $type_info_ref = $INFO_FOR{$type};
        my $filename      = $type_info_ref->{filename};
        my $suffix        = $type_info_ref->{filename_suffix};
        my $content_type  = $type_info_ref->{content_type};

        # Determine the path to the file.
        my $data_dir = $data_dir_of{ ident $self };
        if ( !defined $filename ) {
            $filename = $prefix . $suffix;
        }
        my $path = File::Spec->catfile( $data_dir, $filename );

        # Get the file contents.
        my $contents = slurp $path;

        # Build and return the file information.
        return {
            filename     => $filename,
            content_type => $content_type,
            contents     => $contents,
        };
    }

    ##########################################################################
    # Usage      : $types = $retriever->get_file_types();
    #
    # Purpose    : Returns the list of available file types.
    #
    # Returns    : The list of file types.
    #
    # Parameters : None.
    #
    # Throws     : No exceptions.
    sub get_file_types {
        return keys %INFO_FOR;
    }

    ##########################################################################
    # Usage      : $suffixes_ref = $retriever->get_url_suffixes($qualifier);
    #
    # Purpose    : Returns a reference to a hash that maps file types to URL
    #              suffixes.
    #
    # Returns    : The list of file types.
    #
    # Parameters : $qualifier - used to disambiguate some URLs.
    #
    # Throws     : No exceptions.
    sub get_url_suffixes {
        my ( $self, $qualifier ) = @_;

        # Create the list of url suffixes.
        my %url_suffix_for;
        for my $file_type ( keys %INFO_FOR ) {
            my $file_type_info_ref = $INFO_FOR{$file_type};
            my $file_format        = $file_type_info_ref->{file_format};

            # Determine the trailing part of the URL suffix.
            my $partial_suffix
                = defined $file_type_info_ref->{filename}
                ? $file_type
                : "$file_type/$qualifier";
            my $camel_case_file_type = camel_case_phrase($file_type);

            # Create the URL suffix for every supported action.
            for my $action qw( get download ) {
                my $description = "$action\u$camel_case_file_type";
                my $full_suffix = "$action/$partial_suffix";
                $url_suffix_for{$description} = {
                    'relativeUrl' => $full_suffix,
                    'fileFormat'  => $file_format,
                };
            }
        }

        return \%url_suffix_for;
    }
}

1;
__END__
