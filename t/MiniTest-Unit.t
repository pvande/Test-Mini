use Test::More tests => 12;

use strict;
use warnings;

use B;
use B::Deparse;

my $END;

{ package Mock::TestCase; 1; }
{
  package Mock::Logger;
  with 'MiniTest::Unit::Logger';

  push @ARGV, qw/ --logger Mock::Logger /;

  1;
}


{
  diag "Test: when run with no test modules, exits with 255";

  $? = 0;
  $END->();
  is $?, 255, 'Exit code';
}

{
  diag "Test: when run with an empty test module, exits with 127";

  @Mock::TestCase::ISA = qw/ MiniTest::Unit::TestCase /;

  $? = 0;
  $END->();
  is $?, 127, 'Exit code';
}

{
  diag "Test: when run with an empty (no assertions) test, exits with 1";

  my $tests_called = 0;
  my @error;

  'Mock::TestCase'->meta->add_method('test_method' => sub { $tests_called++ });

  $? = 0;
  $END->();
  is $?, 1, 'Exit code';

  is $tests_called, 1, 'test_method called';
}

{
  diag "Test: when run with an erroneous test, exits with 1";

  my $tests_called = 0;

  'Mock::TestCase'->meta->add_method('test_method' => sub { $tests_called++; die 'oops'; });

  $? = 0;
  $END->();
  is $?, 1, 'Exit code';

  is $tests_called, 1, 'test_method called';
}

{
  diag "Test: when run with an failing test, exits with 1";

  my $tests_called = 0;

  'Mock::TestCase'->meta->add_method('test_method' => sub { $tests_called++; shift->assert(0); });

  $? = 0;
  $END->();
  is $?, 1, 'Exit code';

  is $tests_called, 1, 'test_method called';
}

{
  diag "Test: when run with a passing test, exits with 0";

  my $tests_called = 0;

  'Mock::TestCase'->meta->add_method('test_method' => sub { $tests_called++; shift->assert(1); });

  $? = 0;
  $END->();
  is $?, 0, 'Exit code';

  is $tests_called, 1, 'test_method called';
}


BEGIN {
  use_ok 'MiniTest::Unit';

  # Fetch the first END block, which should be ours.
  #   $CVref will keep the coderef from being garbage collected.
  my $CVref = B::end_av()->ARRAYelt(0);
  $END = $CVref->object_2svref();

  # Verify that the coderef is ours and uninstall it.
  shift @{ B::end_av()->object_2svref() }
    if is $CVref->GV->STASH->NAME, 'MiniTest::Unit', 'END hook installed';
}