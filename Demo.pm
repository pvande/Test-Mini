use Mini::Unit;
use Math::Trig ();

# # Classic-style Example
# # Test case class extends Mini::Unit::TestCase
# class ClassicTest extends Mini::Unit::TestCase
# {
#   # Only methods matching /^test.+/ will automatically run.
#   method test_do_nothing() { }
#
#   # Pre- and post- actions can be described by declaring the relevant methods.
#   # Avoiding the latter two is recommended, but they are provided for those
#   # interested in them.
#   method setup()    { 'This runs before each test...' }
#   method teardown() { 'This runs after each test...' }
#
#   # Assertion methods are not automatically in scope, but do reside on $self.
#   method test_assert() { $self->assert(1, 'I should pass') }
#   method test_refute() { $self->refute(0, 'I should fail') }
#   method test_skip()   { $self->skip("I've got better things to do") }
#
#   # Assertion methods can be included from Mini::Unit::Assertions.
#   use Mini::Unit::Assertions;
#   method test_local_assert() { assert 1, 'I should pass' }
#   method test_local_refute() { refute 0, 'I should fail' }
#   method test_local_skip()   { skip "I've got better things to do" }
# }
#
# # Sugary Example
# # Mini::Unit also declares the 'testcase' keyword for you, which provides a
# # class definition that automatically includes the basic assertions.
# testcase Foo
# {
#   method test_passes() { assert 1, 'I should pass' }
#   method test_refute() { refute 0, 'I should fail' }
#   method test_skip()   { skip "I've got better things to do" }
#
#   # In addition, a 'testcase'-declared class allows you to declare tests with
#   # the 'test' keyword.
#   test keyword_passes { assert 1, 'I should pass' }
#   test keyword_refute { refute 0, 'I should fail' }
#   test keyword_skip   { skip "I've got better things to do" }
#
#   # Pre- and post- actions can be declared with the 'setup' and 'teardown'
#   # keywords; multiple invocations will execute in order of declaration.
#   setup    { 'This runs before each test...' }
#   teardown { 'This runs after each test...' }
# }

# Assertion Test
testcase Assertions
{
  # assert($test, $msg?) -- test the truthiness of $test
  test assert { assert 1 }

  # assert_block($msg_or_block, $block?) -- test the truthiness of the return
  # value from $block (or $msg_or_block, if $block not defined)
  test assert_block { assert_block sub { 1 } }

  # assert_empty($container, $msg?) -- test the emptiness of various containers;
  # anything implementing 'is_empty' may be a $container
  test assert_empty_with_arrayref { assert_empty [] }
  test assert_empty_with_hashref  { assert_empty {} }
  test assert_empty_with_string   { assert_empty '' }
  test assert_empty_with_object   { assert_empty Mock::Bag->new() }

  # assert_equal($expected, $actual, $msg?) -- test whether $expected and
  # $actual are equivalent; number-like strings are tested for numerical
  # equivalence, anything implementing an 'equals' method will rely on that
  # result, and everything else will be checked for structural equivalence
  test assert_equal_with_string   { assert_equal 'foo', lc('FOO') }
  test assert_equal_with_number   { assert_equal 3, 3.00 }
  test assert_equal_with_arrayref { assert_equal [ 1, 2 ], [ qw/ 1 2 / ] }
  test assert_equal_with_hashref  { assert_equal { a => 1 }, { a => 1 } }
  test assert_equal_with_object   { assert_equal Mock::Bag->new(), Mock::Bag->new() }
  test assert_equal_with_undef    { assert_equal undef, []->[0] }
  # Aliases for assert_equal
  test assert_eq                  { assert_eq 'foo', lc('FOO') }

  # assert_in_delta($expected, $actual, $delta, $msg?) -- tests whether $actual
  # is within +/- $delta of $expected
  test assert_in_delta { assert_in_delta Math::Trig::pi, (22.0 / 7.0), 0.0013 }

  # assert_in_epsilon($a, $b, $epsilon, $msg?) -- test that the difference
  # between $a and $b is within +/- $epsilon of the smaller operand
  test assert_in_epsilon { assert_in_epsilon Math::Trig::pi, (22.0 / 7.0), 1/1000.0 }

  # assert_can($obj, $method, $msg?) -- test the ability of an object to respond
  # to a particular method
  test assert_can_with_object    { assert_can Mock::Bag->new(), 'items' }
  test assert_can_with_string    { assert_can 'foo', 'length' }
  test assert_can_with_reference { assert_can [], 'length' }  # Thanks Autobox!
  test assert_can_with_undef     { assert_can undef, 'can' }
  # Aliases for assert_can
  test assert_respond_to         { assert_respond_to Mock::Bag->new, 'items' }

  # assert_contains($container, $obj, $msg?) -- test whether $container has at
  # least one instance of $obj; anything implementing 'contains' may be a
  # $container
  test assert_contains_with_arrayref { assert_contains [ 'a' ], 'a' }
  test assert_contains_with_hashref  { assert_contains { a => 42 }, 'a' }
  test assert_contains_with_string   { assert_contains 'container', 'a' }
  test assert_contains_with_object   { assert_contains Mock::Bag->new(), 'a'}
  # Aliases for assert_contains
  test assert_includes               { assert_includes Mock::Bag->new(), 'a'}

  # assert_isa($obj, $type, $msg?) -- test whether $obj inherits from $type
  test assert_isa     { assert_isa Mock::Bag->new(), 'Mock::Collection' }
  # Aliases for assert_isa
  test assert_is_a    { assert_is_a Mock::Bag->new(), 'Mock::Collection' }

  # assert_does($obj, $role, $msg?) -- test whether $obj uses the $role role
  test assert_does    { assert_does Mock::Bag->new(), 'Mock::Enumerable' }

  # assert_kind_of($obj, $type, $msg?) -- test whether $obj either inherits from
  # $type or performs the $type role
  test assert_kind_of_with_class { assert_kind_of Mock::Bag->new(), 'Mock::Collection' }
  test assert_kind_of_with_role  { assert_kind_of Mock::Bag->new(), 'Mock::Enumerable' }

  # assert_instance_of($obj, $type, $msg?) -- test whether $obj is an instance
  # of $type
  test assert_instance_of { assert_instance_of Mock::Bag->new(), 'Mock::Bag' }

  # assert_match($pattern, $string, $msg?) -- test whether $pattern matches
  # $string
  test assert_match { assert_match qr/test/, 'a test string' }

  # assert_undef($obj, $msg?) -- test that $obj is not defined
  test assert_undef { assert_undef []->[0] }
}

role Mock::Enumerable
{
  method is_empty()         { 1 }
  method items()            { 0 }
  method contains(Any $obj) { $obj eq 'a' }
}

class Mock::Collection { }
class Mock::Bag extends Mock::Collection with Mock::Enumerable {}