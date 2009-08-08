use Mini::Unit;

# Classic-style Example
# Test case class extends Mini::Unit::TestCase
class ClassicTest extends Mini::Unit::TestCase
{
  # Only methods matching /^test.+/ will automatically run.
  method test_do_nothing() { }

  # Assertion methods are not automatically in scope, but do reside on $self.
  method test_assert() { $self->assert(1, 'I should pass') }
  method test_refute() { $self->refute(0, 'I should fail') }
  method test_skip()   { $self->skip("I've got better things to do") }

  # Assertion methods can be included from Mini::Unit::Assertions.
  use Mini::Unit::Assertions;
  method test_local_assert() { assert 1, 'I should pass' }
  method test_local_refute() { refute 0, 'I should fail' }
  method test_local_skip()   { skip "I've got better things to do" }
}

# Sugary Example
# Mini::Unit also declares the 'testcase' keyword for you, which provides a
# class definition that automatically includes the basic assertions.
testcase Foo
{
  method test_passes() { assert 1, 'I should pass' }
  method test_refute() { refute 0, 'I should fail' }
  method test_skip()   { skip "I've got better things to do" }

  # In addition, a 'testcase'-declared class allows you to declare tests with
  # the 'test' keyword.
  test keyword_passes { assert 1, 'I should pass' }
  test keyword_refute { refute 0, 'I should fail' }
  test keyword_skip   { skip "I've got better things to do" }
}

# testcase Bar extends Foo
# {
#   method test_two { assert(0, 'This thing fails!') }
#
#   method test_die { die 'foo' }
#   # TODO: Implement the `test` keyword
#   # TODO: Implement the `setup` keyword
#   # TODO: Implement the `teardown` keyword
# }

# TODO: `testcase` should refuse to extend non-TestCases
# class NonTestCase { sub run {} }
# testcase Baz extends NonTestCase { }

# TODO: Make anonymous `testcase`s work, especially for the nested case
# testcase quxx {
#   after setup { ... }
#   before teardown { ... }
#
#   method test_one { ... }
#
#   testcase { # package quxx::case1
#     after setup { ... } # wraps quxx::setup
#     before teardown { ... } # wraps quxx::teardown
#
#     method test_one { ... } # outer tests don't persist
#   }
#
#   testcase fuzz { # package quxx::fuzz
#
#   }
# }