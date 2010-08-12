use Test::More tests => 13;

use strict;
use warnings;

use B;

my $END;

{ package Mock::TestCase; 1; }
{
  package Mock::Logger;
  use Moose;
  extends 'Test::Mini::Logger';
  1;
}

sub run_tests { Test::Mini::Unit::Runner->new(logger => 'Mock::Logger')->run() }

{
  note 'Test: when run with no test modules, exits with 255';

  is run_tests(), 255, 'Exit code';
}

{
  note 'Test: when run with an empty test module, exits with 127';

  @Mock::TestCase::ISA = qw/ Test::Mini::Unit::TestCase /;

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

  Test::Mini::Unit::Runner->meta->make_mutable();
  Test::Mini::Unit::Runner->meta->add_method(run => sub { return 42 });

  $END->();
  is $?, 42, 'Checking $?';
}

BEGIN {
  use_ok 'Test::Mini::Unit';
  use List::Util qw/ first /;
  use B qw/ end_av /;

  my $index = first {
    my $cv = end_av->ARRAYelt($_);
    ref $cv eq 'B::CV' && $cv->STASH->NAME eq 'Test::Mini::Unit';
  } 0..(end_av->MAX);

  ok defined($index), 'END hook installed';

  $END = end_av->ARRAYelt($index)->object_2svref();
  splice(@{ end_av()->object_2svref() }, $index, 1);
}
