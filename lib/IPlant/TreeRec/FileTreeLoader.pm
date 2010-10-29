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
