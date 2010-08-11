use Test::Mini::Unit;

role Mock::Enumerable
{
  has is_empty  => (is => 'ro');
  has _equals   => (is => 'ro', init_arg => 'equals');
  has _contains => (is => 'ro', init_arg => 'contains');

  method equals(@)   { $self->_equals() }
  method contains(@) { $self->_contains() }
}

class Mock::Dummy { }
class Mock::Collection with Mock::Enumerable { }
class Mock::Bag extends Mock::Collection { }

testcase Test::Mini::Assertions::Test
{
  use aliased 'Test::Mini::Assertions';
  sub assert_passes(&;$)
  {
    my ($code, $msg) = @_;
    $msg .= "\n" if $msg;

    my $failures = 0;
    Assertions->meta->add_method(assert => sub {
      my ($class, $test, $msg) = @_;
      $failures += !$test;
    });

    $code->();
    refute($failures, ($msg || '') . 'test should have passed');
  }

  sub assert_fails(&;$)
  {
    my ($code, $msg) = @_;
    $msg .= "\n" if $msg;

    my $failures = 0;
    Assertions->meta->add_method(assert => sub {
      my ($class, $test, $msg) = @_;
      $failures += !$test;
    });

    $code->();
    assert($failures, ($msg || '') . 'test should have failed');
  }

  sub assert_error(&;$)
  {
    my ($code, $msg) = @_;
    $msg .= "\n" if $msg;
    Assertions->meta->add_method(assert => sub {});
    eval { $code->() };
    assert(Exception::Class->caught(), ($msg || '') . "test should have raised error");
  }

  test refute {
    assert_passes {
      Assertions->refute(0);
    } '$false_value';

    assert_passes {
      Assertions->refute(undef, 'Undef is a falsey value');
    } '$false_value, $msg';

    assert_fails {
      Assertions->refute(1);
    } '$true_value';

    assert_fails {
      Assertions->refute('truthy', '"truthy" is truthy');
    } '$true_value, $msg';
  }


  test assert_block
  {
    assert_passes {
      Assertions->assert_block(sub { 1 }, 'assert_block');
    } '$true_sub, $msg';
    assert_passes {
      Assertions->assert_block('assert_block', sub { 1 });
    } '$msg, $true_sub';

    assert_fails {
      Assertions->assert_block(sub { 0 }, 'assert_block');
    } '$false_sub, $msg';
    assert_fails {
      Assertions->assert_block('assert_block', sub { 0 });
    } '$msg, $false_sub';

    assert_error {
      Assertions->assert_block(sub { die }, 'assert_block');
    } '$die_sub, $msg';
    assert_error {
      Assertions->assert_block('assert_block', sub { die });
    } '$msg, $die_sub';
    assert_error {
      Assertions->assert_block('assert_block');
    } '$msg';
  }

  test assert_dies
  {
      assert_passes {
          Assertions->assert_dies(sub { die 'OMG!' });
      } "sub { die 'OMG!' } dies";
      assert_passes {
          Assertions->assert_dies(sub { die 'Error on line 26!' }, 'line');
      } "sub { die 'Error on line 26!' } does not die with substring 'line'";

      assert_fails {
          Assertions->assert_dies(sub { 'Pretty flowers...' });
      } "sub { 'Pretty flowers...' } doesn't die";
      assert_fails {
          Assertions->assert_dies(sub { 0 });
      } "sub { 0 } doesn't die";
      assert_fails {
          Assertions->assert_dies(sub { die 'Error on line 26!' }, 'grob');
      } "sub { die 'Error on line 26!' } dies with substring 'grob'";
  }

  test assert_can
  {
    assert_passes {
      Assertions->assert_can(Mock::Bag->new(), 'equals');
    } 'Mock::Bag->can("equals")';

    assert_fails {
      Assertions->assert_can(Mock::Dummy->new, 'equals');
    } 'Mock::Dummy->can("equals")';
  }

  test assert_contains
  {
    assert_passes {
      Assertions->assert_contains([qw/ 1 2 3 /], 2);
    } '[qw/ 1 2 3 /] contains 2';
    assert_passes {
      Assertions->assert_contains('the quick brown fox', 'ick');
    } '"the quick brown fox" contains "ick"';
    assert_passes {
      Assertions->assert_contains({ key => 'value' }, 'key');
    } '{ key => "value" } contains "key"';
    assert_passes {
      Assertions->assert_contains({ key => 'value' }, 'value');
    } '{ key => "value" } contains "value"';
    assert_passes {
      Assertions->assert_contains(Mock::Bag->new(contains => 1), 'x');
    } 'Mock::Bag->new(contains => 1)';

    assert_fails {
      Assertions->assert_contains([qw/ 1 2 3 /], 0);
    } '[qw/ 1 2 3 /] contains 0';
    assert_fails {
      Assertions->assert_contains('the quick brown fox', 'selfish');
    } '"this quick brown fox" contains "selfish"';
    assert_fails {
      Assertions->assert_contains({ key => 'value' }, 'peanuts');
    } '{ key => "value" } contains "peanuts"';
    assert_fails {
      Assertions->assert_contains(Mock::Bag->new(contains => 0), 'x');
    } 'Mock::Bag->new(contains => 0)';

    assert_error {
      Assertions->assert_contains(Mock::Dummy->new(), 'x')
    } 'Mock::Dummy->new() contains "x"';
  }

  test assert_does
  {
    assert_passes {
      Assertions->assert_does('Mock::Bag', 'Mock::Enumerable');
    } '"Mock::Bag" does "Mock::Enumerable"';
    assert_passes {
      Assertions->assert_does(Mock::Bag->new(), 'Mock::Enumerable');
    } 'Mock::Bag->new() does "Mock::Enumerable"';

    assert_fails {
      Assertions->assert_does('Mock::Dummy', 'Mock::Enumerable');
    } '"Mock::Dummy" does "Mock::Enumerable"';
    assert_fails {
      Assertions->assert_does(Mock::Dummy->new(), 'Mock::Enumerable')
    } 'Mock::Dummy->new() does "Mock::Enumerable"';
  }

  test assert_empty
  {
    assert_passes {
      Assertions->assert_empty([]);
    } '[]';
    assert_passes {
      Assertions->assert_empty({});
    } '{}';
    assert_passes {
      Assertions->assert_empty('');
    } '""';
    assert_passes {
      Assertions->assert_empty(Mock::Bag->new(is_empty => 1));
    } 'Mock::Bag->new(is_empty => 1)';

    assert_fails {
      Assertions->assert_empty([ 0 ]);
    } '[ 0 ]';
    assert_fails {
      Assertions->assert_empty({ 0 => undef });
    } '{ 0 => undef }';
    assert_fails {
      Assertions->assert_empty('NONEMPTY');
    } '"NONEMPTY"';
    assert_fails {
      Assertions->assert_empty(Mock::Bag->new(is_empty => 0));
    } 'Mock::Bag->new(is_empty => 0)';

    assert_error {
      Assertions->assert_empty(qr//);
    } 'qr//';
    assert_error {
      Assertions->assert_empty(Mock::Dummy->new());
    } 'Mock::Dummy->new()';
  }

  test assert_equal
  {
    assert_passes {
      Assertions->assert_equal(3.00, 3);
    } '3.00 equals 3';
    assert_passes {
      Assertions->assert_equal(lc('FOO'), 'foo');
    } 'lc("FOO") equals "foo"';
    assert_passes {
      Assertions->assert_equal('INFINITY', 'inf');
    } '"INFINITY" equals "inf"';
    assert_passes {
      Assertions->assert_equal([ qw/ 1 2 / ], [ 1, 2 ]);
    } '[qw/ 1 2 /] equals [ 1, 2 ]';
    assert_passes {
      Assertions->assert_equal({ a => 1 }, { 'a', 1 });
    } '{ a => 1} equals { "a", 1 }';
    assert_passes {
      Assertions->assert_equal(Mock::Dummy->new(), Mock::Dummy->new());
    } 'Mock::Dummy->new()';
    assert_passes {
      Assertions->assert_equal(
        bless([1, 2, 3], 'Mock::Dummy'),
        bless([1, 2, 3], 'Mock::Dummy'),
      );
    } 'blessed [1, 2, 3] equals blessed [1, 2, 3]';
    assert_passes {
      Assertions->assert_equal(Mock::Bag->new(equals => 1), 'anything');
    } 'Mock::Bag->new(equals => 1)';
    assert_passes {
      Assertions->assert_equal([]->[0], undef);
    } '[]->[0] equals undef';
    assert_passes {
      my $c = {};
      $c->{loop} = $c;
      Assertions->assert_equal($c, $c);
    } '<circular reference> equals <circular reference>';
    assert_passes {
      my $thing = "THING";
      Assertions->assert_equal(\\\$thing, \\\$thing);
    } '<deep reference> equals <deep reference>';
    assert_passes {
      my $c = {};
      $c->{loop} = $c;

      Assertions->assert_equal(
        [ { a => undef, b => Mock::Bag->new(equals => 1), c => \$c }, 'abcde' ],
        [ { a => undef, b => Mock::Bag->new()           , c => \$c }, 'abcde' ],
      );
    } '<complex nested object> equals <complex nested object>';

    assert_fails {
      Assertions->assert_equal(3.001, 3);
    } '3.001 equals 3';
    assert_fails {
      Assertions->assert_equal(lc('FO0'), 'foo');
    } 'lc("FO0") equals "foo"';
    assert_fails {
      Assertions->assert_equal('INFINITY', 'information');
    } '"INFINITY" equals "information"';
    assert_fails {
      Assertions->assert_equal([ qw/ 1 b / ], [ 1, 2 ]);
    } '[ qw/ 1 b / ] equals [ 1, 2 ]';
    assert_fails {
      Assertions->assert_equal({ 'a', 2 }, { a => 1 });
    } '{ "a", 2 } equals { a => 1 }';
    assert_fails {
      Assertions->assert_equal(Mock::Bag->new(equals => 0), 'nothing');
    } 'Mock::Bag->new(equals => 0)';
    assert_fails {
      my $dummy = Mock::Dummy->new();
      $dummy->{key} = "value";
      Assertions->assert_equal($dummy, Mock::Dummy->new());
    } 'Mock::Dummy->new()';
    assert_fails {
      Assertions->assert_equal(
        bless([1, 2, 3], 'Mock::Dummy'),
        bless([1, 2, 4], 'Mock::Dummy'),
      );
    } 'blessed [1, 2, 3] equals blessed [1, 2, 4]';
    assert_fails {
      Assertions->assert_equal(0, undef);
    } '0 equals undef';
    assert_fails {
      my $c = {};
      $c->{loop} = $c;

      Assertions->assert_equal(
        [ { a => undef, b => Mock::Bag->new(equals => 0), c => $c }, 'abcde' ],
        [ { a => undef, b => Mock::Bag->new()           , c => $c }, 'abcde' ],
      );
    } '<complex nested object> equals <different complex nested object>';
    assert_fails {
      Assertions->assert_equal(
        [ 1, 'abcde',         ],
        [ 1, 'abcde', 3.14159 ],
      );
    } '[ 1, "abcde" ] equals [ 1, "abcde", 3.14159 ]';
    assert_fails {
      my $thing = "THING";
      Assertions->assert_equal(\\$thing, \\\$thing);
    } '<deep reference> equals <deeper reference>';
  }

  test assert_kind_of
  {
    assert_passes {
      Assertions->assert_kind_of(Mock::Bag->new(), 'Mock::Collection');
    } 'Mock::Bag->new() is a kind of "Mock::Collection"';
    assert_passes {
      Assertions->assert_kind_of(Mock::Bag->new(), 'Mock::Enumerable');
    } 'Mock::Bag->new() is a kind of "Mock::Enumerable"';
    assert_passes {
      Assertions->assert_kind_of('Mock::Bag', 'Mock::Collection');
    } '"Mock::Bag" is a kind of "Mock::Collection"';
    assert_passes {
      Assertions->assert_kind_of('Mock::Bag', 'Mock::Enumerable');
    } '"Mock::Bag" is a kind of "Mock::Enumerable"';

    assert_fails {
      Assertions->assert_kind_of(Mock::Dummy->new(), 'Mock::Collection');
    } 'Mock::Dummy->new() is a kind of "Mock::Collection"';
    assert_fails {
      Assertions->assert_kind_of(Mock::Dummy->new(), 'Mock::Enumerable');
    } 'Mock::Dummy->new() is a kind of "Mock::Enumerable"';
    assert_fails {
      Assertions->assert_kind_of('Mock::Dummy', 'Mock::Collection');
    } '"Mock::Dummy" is a kind of "Mock::Collection"';
    assert_fails {
      Assertions->assert_kind_of('Mock::Dummy', 'Mock::Enumerable');
    } '"Mock::Dummy" is a kind of "Mock::Enumerable"';

    assert_error {
      Assertions->assert_kind_of([], 'Mock::Collection');
    } '[] is a kind of "Mock::Collection"';
  }

  test assert_in_delta
  {
    assert_passes {
      Assertions->assert_in_delta(-1, 1, 2);
    } '(-1) - 1 <= 2';
    assert_passes {
      Assertions->assert_in_delta(1, -1, 2);
    } '1 - (-1) <= 2';

    assert_fails {
      Assertions->assert_in_delta(-1, 1, 1.8);
    } '(-1) - 1 <= 1.8';
  }

  test assert_in_epsilon
  {
    assert_passes {
      Assertions->assert_in_epsilon(9999, 10000);
    } '9999 is within 0.1% of 10000';

    assert_fails {
      Assertions->assert_in_epsilon(9999, 10000, 0.0001);
    } '9999 is within 0.01% of 10000';
  }

  test assert_instance_of
  {
    assert_passes {
      Assertions->assert_instance_of(Mock::Bag->new(), 'Mock::Bag');
    } 'Mock::Bag->new() is an instance of Mock::Bag';

    assert_fails {
      Assertions->assert_instance_of(Mock::Bag->new(), 'Mock::Collection');
    } 'Mock::Bag->new() is an instance of Mock::Collection';
  }

  test assert_isa
  {
    assert_passes {
      Assertions->assert_isa('Mock::Bag', 'Mock::Bag');
    } 'Mock::Bag is a Mock::Bag';
    assert_passes {
      Assertions->assert_isa('Mock::Bag', 'Mock::Collection');
    } 'Mock::Bag is a Mock::Collection';
    assert_passes {
      Assertions->assert_isa(Mock::Bag->new(), 'Mock::Bag');
    } 'Mock::Bag->new() is a Mock::Bag';
    assert_passes {
      Assertions->assert_isa(Mock::Bag->new(), 'Mock::Collection');
    } 'Mock::Bag->new() is a Mock::Collection';

    assert_fails {
      Assertions->assert_isa(Mock::Bag->new(), 'Mock::Enumerable');
    } 'Mock::Bag->new() is a Mock::Enumerable';
    assert_fails {
      Assertions->assert_isa(Mock::Bag->new(), 'Mock::Dummy');
    } 'Mock::Bag->new() is a Mock::Dummy';
  }

  test assert_match
  {
    assert_passes {
      Assertions->assert_match('Four score and seven years ago...', qr/score/);
    } '/score/ matches "Four score and seven years ago..."';

    assert_fails {
      Assertions->assert_match('Four score and seven years ago...', qr/awesome/);
    } '/awesome/ matches "Four score and seven years ago..."';
  }

  test assert_undef
  {
    assert_passes {
      Assertions->assert_undef({}->{key});
    } '{}->{key} is undefined';
    assert_passes {
      Assertions->assert_undef([]->[0]);
    } '[]->[0] is undefined';
    assert_passes {
      Assertions->assert_undef(undef);
    } 'undef is undefined';

    assert_fails {
      Assertions->assert_undef(0);
    } '0 is undefined';
    assert_fails {
      Assertions->assert_undef('');
    } '"" is undefined';
    assert_fails {
      Assertions->assert_undef('NaN');
    } 'NaN is undefined';
  }
}
