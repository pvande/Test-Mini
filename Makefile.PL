use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker 6.31;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'base'             => 0,
    'Data::Inspect'    => '0.03',
    'Exception::Class' => '1.30',
    'Getopt::Long'     => '2.38',
    'List::Util'       => '1.33',
    'MRO::Compat'      => '0.10',
    'namespace::clean' => '0.14',
    'Scalar::Util'     => '1.21',
    'strict'           => 0,
    'Time::HiRes'      => '1.9719',
    'Try::Tiny'        => '0.04',
    'warnings'         => 0,
);

my @TEST_REQUIRES = (
    'aliased'       => '0.30',
    'B'             => '0',
    'IO::Scalar'    => '2.110',
    'Test::More'    => '0.96',
    'Text::Outdent' => '0.01',
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

WriteMakefile(
    'NAME'          => 'Test::Mini',
    'ABSTRACT'      => 'Lightweight xUnit Testing for Perl',
    'VERSION_FROM'  => 'lib/Test/Mini.pm',
    'AUTHOR'        => 'Pieter van de Bruggen <pvande@cpan.org>',

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    'META_MERGE' => {
        'resources' => {
            'homepage'   => 'https://github.com/pvande/Test-Mini',
            'repository' => 'https://github.com/pvande/Test-Mini.git',
            'bugtracker' => 'https://github.com/pvande/Test-Mini/issues',
        },
    },

    'PREREQ_PM' => { @REQUIRES },

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.31,
          })
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    'test' => {
        'TESTS' => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t t/*/*/*/*/*.t',
    },
    'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

