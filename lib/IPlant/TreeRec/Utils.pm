package IPlant::TreeRec::Utils;

use 5.008000;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( camel_case_keys camel_case_phrase );

our $VERSION = '0.0.2';

##########################################################################
# Usage      : $new_hash_ref = camel_case_keys( $hash_ref );
#
# Purpose    : Converts the keys in the given hash reference from
#              underscore_separated_words or hyphen-separated-words to
#              camelCasedWords.
#
# Returns    : A reference to the converted hash.
#
# Parameters : $hash_ref - a reference to the hash to convert.
#
# Throws     : No exceptions.
sub camel_case_keys {
    my ($hash_ref) = @_;

    # Convert all of the keys to camel case.
    my %converted;
    while ( my ( $key, $value ) = each %{$hash_ref} ) {
        $converted{ camel_case_phrase($key) } = $value;
    }

    return \%converted;
}

##########################################################################
# Usage      : $new_phrase = camel_case_phrase($phrase);
#
# Purpose    : Converts the given underscore_separated_phrase or
#              hyphen-separated-phrase to a camelCasePhrase.
#
# Returns    : The camel-cased phrase.
#
# Parameters : $phrase - the phrase to convert.
#
# Throws     : No exceptions.
sub camel_case_phrase {
    my ($phrase) = @_;

    # Convert the word to camel case and return it.
    my ( $first_word, @remaining_words ) = split m/[-_]/xms, $phrase;
    return $first_word . join q{}, map {"\u\L$_"} @remaining_words;
}

1;
__END__
