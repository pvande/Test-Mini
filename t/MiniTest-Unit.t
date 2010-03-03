use Test::More tests => 13;

use strict;
use warnings;

use B;

my $END;

{ package Mock::TestCase; 1; }
{
  package Mock::Logger;
  use Moose;
  with 'MiniTest::Unit::Logger';
  1;
}

sub run_tests { MiniTest::Unit::Runner->new(logger => 'Mock::Logger')->run() }

{
  note 'Test: when run with no test modules, exits with 255';

  is run_tests(), 255, 'Exit code';
}

{
  note 'Test: when run with an empty test module, exits with 127';

  @Mock::TestCase::ISA = qw/ MiniTest::Unit::TestCase /;

  is run_tests(), 127, 'Exit code';
}

{
  note 'Test: when run with an empty (no assertions) test, exits with 1';

  my $tests_called = 0;

  'Mock::TestCase'->meta->add_method('test_method' => sub { $tests_called++ });

  is run_tests(), 1, 'Exit code';
  is $tests_called, 1, 'test_method called';
}

{
  note 'Test: when run with an erroneous test, exits with 1';

  my $tests_called = 0;

  'Mock::TestCase'->meta->add_method('test_method' => sub { $tests_called++; die 'oops'; });

  is run_tests(), 1, 'Exit code';
  is $tests_called, 1, 'test_method called';
}

{
  note 'Test: when run with an failing test, exits with 1';

  my $tests_called = 0;

  'Mock::TestCase'->meta->add_method('test_method' => sub { $tests_called++; shift->assert(0); });

  is run_tests(), 1, 'Exit code';
  is $tests_called, 1, 'test_method called';
}

{
  note 'Test: when run with a passing test, exits with 0';

  my $tests_called = 0;

  'Mock::TestCase'->meta->add_method('test_method' => sub { $tests_called++; shift->assert(1); });

  is run_tests(), 0, 'Exit code';
  is $tests_called, 1, 'test_method called';
}

{
  note 'Test: installed END block exits with result from MT::U::Runner#run';

  MiniTest::Unit::Runner->meta->make_mutable();
  MiniTest::Unit::Runner->meta->add_method(run => sub { return 42 });

  $END->();
  is $?, 42;
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
