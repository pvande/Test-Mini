use Mini::Unit;

testcase Foo
{
  method test_one { assert(1) }
}

testcase Bar extends Foo
{
  method test_two { assert(0, 'This thing fails!') }

  # TODO: Implement the `test` keyword
  # TODO: Implement the `setup` keyword
  # TODO: Implement the `teardown` keyword
}

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

class Demo::Tests extends Mini::Unit::TestCase
{
  use Mini::Unit::Assertions;
}