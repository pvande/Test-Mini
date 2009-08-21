use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MiniTest::Unit',
    VERSION_FROM      => 'lib/MiniTest/Unit.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MiniTest/Unit.pm', # retrieve abstract from module
       AUTHOR         => 'Pieter Vande Bruggen <pvande@local>') : ()),
);
