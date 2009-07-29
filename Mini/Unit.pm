use MooseX::Declare;
use Mini::Unit::Runner;

Mini::Unit::Runner->autorun();

if ($0 eq __FILE__) {

  class TestCase extends Mini::Unit::TestCase
  {
    use Mini::Unit::Assertions;

    method test_pass { assert(1); assert(1); sleep 1 }
    method test_fail { sleep 1; assert(0, 'Failed HARD!') }
    method test_skipped { sleep 1; Mini::Unit::Skip->throw('Not Yet Implemented') }
    method test_error { sleep 1; die 'fooblibarioafr!'; Mini::Unit::Foo->frobozz() }
  }
}

1;