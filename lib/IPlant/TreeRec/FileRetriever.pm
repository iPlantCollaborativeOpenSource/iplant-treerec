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
    },
    'fat-tree-image' => {
        filename_suffix => '_fattree.nhx.gif',
        content_type    => 'image/gif',
    },
    'gene-tree' => {
        filename_suffix => '_genetree.nhx',
        content_type    => 'text/plain',
    },
    'gene-tree-image' => {
        filename_suffix => '_genetree.nhx.png',
        content_type    => 'image/png',
    },
    'amino-acid-sequence' => {
        filename_suffix => '_AA.fa',
        content_type    => 'text/plain',
    },
    'amino-acid-multiple-sequence-alignment' => {
        filename_suffix => '_AA.mfa',
        content_type    => 'text/plain',
    },
    'dna-sequence' => {
        filename_suffix => '_DNA.fa',
        content_type    => 'text/plain',
    },
    'dna-multiple-sequence-alignment' => {
        filename_suffix => '_DNA.mfa',
        content_type    => 'text/plain',
    },
    'species-tree-image' => {
        filename     => 'species_tree.png',
        content_type => 'image/png',
    },
    'species-tree' => {
        filename     => 'species_tree.nwk',
        content_type => 'text/plain',
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
                $url_suffix_for{$description} = $full_suffix;
            }
        }

        return \%url_suffix_for;
    }
}

1;
__END__

=head1 NAME

<Module: : Name>   <One-line description of module's purpose>

=head1 VERSION

The initial template usually just has:
This documentation refers to <Module: : Name> version 0. 0. 1.

=head1 SYNOPSIS

    use <Module: : Name>;
    # Brief but working code example(s) here showing the most common usage(s)
    # This section will be as far as many users bother reading,
    # so make it as educational and exemplary as possible.

=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i. e. , =head2, =head3, etc. ).

=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.
These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module provides.
Name the section accordingly.

In an object-oriented module, this section should begin with a sentence of the
form "An object of this class represents. . . ", to give the reader a high-level
context to help them understand the methods that are subsequently described.

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also a list of restrictions on the features the module does provide:
data types that cannot be handled, performance issues and the circumstances
in which they may arise, practical limitations on the size of data sets,
special cases that are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.
Please report problems to <Maintainer name(s)>  (<contact address>)
Patches are welcome.

=head1 AUTHOR

<Author name(s)> (<contact address>)

=head1 LICENCE AND COPYRIGHT

Copyright (c) <year> <copyright holder> (<contact address>). All rights reserved.
followed by whatever licence you wish to release it under.
For Perl code that is often just:

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
