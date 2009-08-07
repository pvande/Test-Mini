use Mini::Unit;

class UnderTest extends Mini::Unit::TestCase {
  use Helper;
  method foo($inverse_retval) { return $self->invert($inverse_retval) }
  sub invert { Helper->new->doit() }
}

testcase Foo
{
  use Mini::Unit::Assertions;
  method test_passes { assert(1) }
  method test_fails  { assert(0) }
  method test_skips  { skip "I'm skipping out..." }
  method test_dies   { confess 'woe is me!' }
  method test_stack_trace { UnderTest->new()->foo(0) }
}
#
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