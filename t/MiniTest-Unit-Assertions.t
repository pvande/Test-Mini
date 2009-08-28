use MiniTest::Unit;

role Mock::Collection
{
  has is_empty  => (is => 'ro');
  has _equals   => (is => 'ro', init_arg => 'equals');
  has _contains => (is => 'ro', init_arg => 'contains');

  method equals(@)   { $self->_equals() }
  method contains(@) { $self->_contains() }
}

class Mock::Dummy { }
class Mock::Bag with Mock::Collection { }

testcase MiniTest::Unit::Assertions::Test
{
  use aliased 'MiniTest::Unit::Assertions';
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
      Assertions->assert_does('Mock::Bag', 'Mock::Collection');
    } '"Mock::Bag" does "Mock::Collection"';
    assert_passes {
      Assertions->assert_does(Mock::Bag->new(), 'Mock::Collection');
    } 'Mock::Bag->new() does "Mock::Collection"';

    assert_fails {
      Assertions->assert_does('Mock::Dummy', 'Mock::Collection');
    } '"Mock::Dummy" does "Mock::Collection"';
    assert_fails {
      Assertions->assert_does(Mock::Dummy->new(), 'Mock::Collection')
    } 'Mock::Dummy->new() does "Mock::Collection"';
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
      MiniTest::Unit::Assertions->assert_equal(3, 3.00);
    } '3 equals 3.00';
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal('foo', lc('FOO'));
    } '"foo" equals lc("FOO")';
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal('inf', 'INFINITY');
    } '"inf" equals "INFINITY"';
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal([ 1, 2 ], [ qw/ 1 2 / ]);
    } '[ 1, 2 ] equals [qw/ 1 2 /]';
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal({ a => 1 }, { 'a', 1 });
    } '{ a => 1} equals { "a", 1 }';
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal(Mock::Bag->new(equals => 1), 'anything');
    } 'Mock::Bag->new(equals => 1)';
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal(undef, []->[0]);
    } 'undef equals []->[0]';
    assert_passes {
        my $c = {};
        $c->{loop} = $c;
        MiniTest::Unit::Assertions->assert_equal($c, $c);
    } '<circular reference> equals <circular reference>';
    assert_passes {
      my $thing = "THING";
      MiniTest::Unit::Assertions->assert_equal(\\\$thing, \\\$thing);
    } '<deep reference> equals <deep reference>';
    assert_passes {
      my $c = {};
      $c->{loop} = $c;

      MiniTest::Unit::Assertions->assert_equal(
        [ { a => undef, b => Mock::Bag->new(equals => 1), c => \$c }, 'abcde' ],
        [ { a => undef, b => Mock::Bag->new()           , c => \$c }, 'abcde' ],
      );
    } '<complex nested object> equals <complex nested object>';

    assert_fails {
      MiniTest::Unit::Assertions->assert_equal(3, 3.001);
    } '3 equals 3.001';
    assert_fails {
      MiniTest::Unit::Assertions->assert_equal('foo', lc('FO0'));
    } '"foo" equals lc("FO0")';
    assert_fails {
      MiniTest::Unit::Assertions->assert_equal('information', 'INFINITY');
    } '"information" equals "INFINITY"';
    assert_fails {
      MiniTest::Unit::Assertions->assert_equal([ 1, 2 ], [ qw/ 1 b / ]);
    } '[ 1, 2 ] equals [ qw/ 1 b / ]';
    assert_fails {
      MiniTest::Unit::Assertions->assert_equal({ a => 1 }, { 'a', 2 });
    } '{ a => 1 } equals { "a", 2 }';
    assert_fails {
      MiniTest::Unit::Assertions->assert_equal(Mock::Bag->new(equals => 0), 'nothing');
    } 'Mock::Bag->new(equals => 0)';
    assert_fails {
      MiniTest::Unit::Assertions->assert_equal(undef, 0);
    } 'undef equals 0';
    assert_fails {
      my $c = {};
      $c->{loop} = $c;

      MiniTest::Unit::Assertions->assert_equal(
        [ { a => undef, b => Mock::Bag->new(equals => 0), c => $c }, 'abcde' ],
        [ { a => undef, b => Mock::Bag->new()           , c => $c }, 'abcde' ],
      );
    } '<complex nested object> equals <different complex nested object>';
    assert_fails {
      MiniTest::Unit::Assertions->assert_equal(
        [ 1, 'abcde',         ],
        [ 1, 'abcde', 3.14159 ],
      );
    } '[ 1, "abcde" ] equals [ 1, "abcde", 3.14159 ]';
    assert_fails {
      my $thing = "THING";
      MiniTest::Unit::Assertions->assert_equal(\\$thing, \\\$thing);
    } '<deep reference> equals <deeper reference>';
  }

  assert_in_delta: {
    test assert_in_delta_passes
    {
      assert_passes {
        MiniTest::Unit::Assertions->assert_in_delta(-1, 1, 2);
      };
    }

    test assert_in_delta_passes_with_reversed_arguments
    {
      assert_passes {
        MiniTest::Unit::Assertions->assert_in_delta(1, -1, 2);
      };
    }

    test assert_in_delta_fails
    {
      assert_fails {
        MiniTest::Unit::Assertions->assert_in_delta(-1, 1, 1.8);
      };
    }
  }

  assert_in_epsilon: {
    test assert_in_epsilon
    {
      assert_passes {
        MiniTest::Unit::Assertions->assert_in_epsilon(10000, 9999);
      };

      assert_fails {
        MiniTest::Unit::Assertions->assert_in_epsilon(10000, 9999, 0.0001);
      }
    }
  }

}
