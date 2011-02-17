use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'IPlant::TreeRec',
    VERSION_FROM => 'lib/IPlant/TreeRec.pm',    # finds $VERSION
    PREREQ_PM    => {
        'Apache2::Const'         => 0,
        'Apache2::RequestUtil'   => 0,
        'Apache2::REST'          => 0,
        'Apache2::REST::Handler' => 0,
        'Bio::TreeIO'            => 0,
        'Bio::Tree::NodeNHX'     => 0,
        'Carp'                   => 0,
        'Class::Std::Utils'      => 0,
        'Data::Dumper'           => 0,
        'DBIx::Class'            => 0,
        'English'                => 0,
        'Exception::Class'       => 0,
        'File::Path'             => 0,
        'File::Spec'             => 0,
        'HTML::TagList'          => 0.35,
        'IO::Handle'             => 0,
        'IPC::Run'               => 0,
        'JSON'                   => 0,
        'List::MoreUtils'        => 0,
        'Memoize'                => 0,
        'Perl6::Slurp'           => 0,
        'Readonly'               => 0,
        'Test::More'             => 0,
        'Time::HiRes'            => 0,
    },
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT_FROM => 'lib/IPlant/TreeRec.pm',
            AUTHOR        => 'Dennis Roberts <dennis@iplantcollaborative.org>'
            )
        : ()
    ),
);
