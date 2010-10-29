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
