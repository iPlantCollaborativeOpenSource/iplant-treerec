package IPlant::TreeRec::X;

use 5.008000;

use strict;
use warnings;

our $VERSION = '0.0.1';

use Exception::Class (

    # The base exception for this library.
    'IPlant::TreeRec::Exception',

    # Thrown when a database error occurs.
    'IPlant::TreeRec::DatabaseException' => {
        'isa' => 'IPlant::TreeRec::Exception',
    },

    # Thrown when an illegal argument is used.
    'IPlant::TreeRec::IllegalArgumentException' => {
        'isa' => 'IPlant::TreeRec::Exception',
    },

    # Thrown when an I/O error occurs.
    'IPlant::TreeRec::IOException' => {
        'isa' => 'IPlant::TreeRec::Exception',
    },

    # Thrown when we can't close a file handle.
    'IPlant::TreeRec::CloseException' => {
        'isa' => 'IPlant::TreeRec::IOException',
    },

    # Thrown when a selected tree can't be located.
    'IPlant::TreeRec::TreeNotFoundException' => {
        'isa' => 'IPlant::TreeRec::Exception',
    },

    # Thrown when a gene family can't be located.
    'IPlant::TreeRec::GeneFamilyNotFoundException' => {
        'isa' => 'IPlant::TreeRec::Exception',
    },

    # Thrown when a reconciliation can't be located.
    'IPlant::TreeRec::ReconciliationNotFoundException' => {
        'isa' => 'IPlant::TreeRec::Exception',
    },
);

1;
__END__

=head1 NAME

IPlant::TreeRec::X – Exceptions for tree reconciliation classes.

=head1 VERSION

This documentation refers to IPlant::TreeRec::X version 0.0.1.

=head1 SYNOPSIS

    use IPlant::TreeRec::X;

    # A general tree reconciliation exception.
    IPlant::TreeRec::Exception->throw( error => $message );

    # An exception that is thrown when a database error occurs.
    IPlant::TreeRec::DatabaseException->throw( error => $message );

    # An exception that is thrown when an illegal argument is encountered.
    IPlant::TreeRec::IllegalArgumentException->throw( error => $message );

    # An exception that is thrown when an I/O error occurs.
    IPlant::TreeRec::IOException->throw( error => $message );

    # An exception that is thrown when a file can't be closed.
    IPlant::TreeRec::CloseException->throw( error => $message );

    # An exception that is thrown when a tree can't be loacated.
    IPlant::TreeRec::TreeNotFoundException->throw( error => $message );

    # An exception that is thrown when a gene family can't be located.
    IPlant::TreeRec::GeneFamilyNotFoundException->throw( error => $message );

    # An exception that is thrown when a reconciliation can't be located.
    IPlant::TreeRec::ReconciliationNotFoundException->throw(
        error => $message );

=head1 DESCRIPTION

Exceptions for iPlant tree reconciliation classes.

=head2 IPlant::TreeRec::Exception

A general tree reconciliation exception.  This is the base exception class for
all other exceptions in the tree reconciliation library.

=head2 IPlant::TreeRec::DatabaseException

Thrown when a database error occurs.

=head2 IPlant::TreeRec::IllegalArgumentException

Thrown when an illegal argument value is passed to any subroutine.

=head2 IPlant::TreeRec::IOException

Thrown when a general I/O exception occurs.

=head2 IPlant::TreeRec::CloseException

Thrown when a file handle can't be closed.

=head2 IPlant::TreeRec::TreeNotFoundException

Thrown when either a gene tree or a species tree can't be found.

=head2 IPlant::TreeRec::GeneFamilyNotFoundException

Thrown when a gene family can't be found.

=head2 IPlant::TreeRec::ReconciliationNotFoundException

Thrown when a reconciliation can't be found for a specified gene tree and
species tree.

=head1 DEPENDENCIES

=head2 Exception::Class

This CPAN module is used to generate the exception classes.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. Please report problems to the iPlant
Collaborative.  Patches are welcome.

=head1 AUTHOR

Dennis Roberts (dennis@iplantcollaborative.org)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010 iPlant Collaborative. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
