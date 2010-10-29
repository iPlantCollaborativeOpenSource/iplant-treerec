package IPlant::TreeRec::BlastArgs;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Carp;
use Class::Std::Utils;
use English qw( -no_match_vars );
use File::Spec;
use JSON qw();
use Readonly;

# Parameter values for supported sequence types.
Readonly my %TYPE_INFO_FOR => (
    nucleotide => {
        executable => 'tblastx',
        database   => 'all_DNA.fa',
    },
    protein => {
        executable => 'blastp',
        database   => 'all_AA.fa',
    },
);

{
    my %executable_of;
    my %sequence_of;
    my %database_of;
    
    ##########################################################################
    # Usage      : $blast_args = IPlant::TreeRec::BlastArgs->_new(
    #                  {   executable => $executable_path,
    #                      sequence   => $sequence,
    #                      database   => $database_file_name,
    #                  }
    #              );
    # 
    # Purpose    : Creates a new set of BLAST arguments.
    #
    # Returns    : The new set of blast arguments.
    #
    # Parameters : executable - the name of the executable file.
    #              sequence   - the query sequence.
    #              database   - the name of the database file.
    #
    # Throws     : No exceptions.
    sub _new {
        my ( $class, $args_ref ) = @_;

        # Extract the arguments.
        my $executable = $args_ref->{executable};
        my $sequence   = $args_ref->{sequence};
        my $database   = $args_ref->{database};

        # Create the new object.
        my $self = bless anon_scalar(), $class;

        # Set the object properties.
        $executable_of{ ident $self } = $executable;
        $sequence_of{ ident $self } = $sequence;
        $database_of{ ident $self } = $database;

        return $self;
    }

    ##########################################################################
    # Usage      : $blast_args = IPlant::TreeRec::BlastArgs->from_json($json);
    #
    # Purpose    : Creates a BLAST arguments object from a JSON string in the
    #              format:
    #
    #              {   "sequence":     <sequence>,
    #                  "sequenceType": <sequenceType>,
    #              }
    #
    #              Available sequence types are "nucleotide" and "protein".
    #
    # Returns    : The new BLAST arguments object.
    #
    # Parameters : $json - the JSON string.
    #
    # Throws     : No exceptions.
    sub from_json {
        my ( $class, $json ) = @_;

        # Extract the arguments from the JSON.
        my $json_ref      = JSON->new->decode($json);
        my $sequence_type = $json_ref->{'sequenceType'};
        my $sequence      = $json_ref->{'sequence'};

        # Both the sequence type and sequence are required.
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $sequence_type || !defined $sequence;

        # Get the information we need to create the object.
        my $type_info_ref = $TYPE_INFO_FOR{$sequence_type};
        IPlant::TreeRec::IllegalArgumentException->throw()
            if !defined $type_info_ref;

        # Create the BLAST arguments object.
        return $class->_new(
            {   'executable' => $type_info_ref->{executable},
                'database'   => $type_info_ref->{database},
                'sequence'   => $sequence,
            }
        );
    }

    ##########################################################################
    # Usage      : $sequence = $blast_args->get_sequence();
    #
    # Purpose    : Gets the sequence.
    #
    # Returns    : The sequence.
    #
    # Parameters : None.
    #
    # Throws     : No exceptions.
    sub get_sequence {
        my ($self) = @_;
        return $sequence_of{ ident $self };
    }

    ##########################################################################
    # Usage      : @command = $blast_args->build_command( $exe_dir, $db_dir );
    #
    # Purpose    : Builds the command to execute in order to perform the BLAST
    #              search.
    #
    # Returns    : The command.
    #
    # Parameters : $exe_dir - the path to the executable file directory.
    #              $db_dir  - the path to the database file directory.
    #
    # Throws     : No exceptions.
    sub build_command {
        my ( $self, $exe_dir, $db_dir ) = @_;

        # Extract the names of the executable and database.
        my $exe_name = $executable_of{ ident $self };
        my $db_name  = $database_of{ ident $self };

        # Build the paths to the executable and database.
        my $exe_path = File::Spec->catfile( $exe_dir, $exe_name );
        my $db_path  = File::Spec->catfile( $db_dir, $db_name );

        # Build and return the command.
        return ( $exe_path, '-db', $db_path, '-outfmt', 6 );
    }
}

1;
__END__

=head1 NAME

<Module: : Name> – <One-line description of module's purpose>

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
