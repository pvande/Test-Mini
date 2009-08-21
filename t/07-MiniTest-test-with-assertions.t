use Test::More tests => 10;

END   { is($?, 0, 'Exit code') };
BEGIN { use_ok('MiniTest::Unit') };

{
  use MooseX::Declare;

  class SuccessLogger with MiniTest::Unit::Logger {
    method pass(ClassName $tc, Str $test) {
      Test::More::pass('Called ->pass on ' . __PACKAGE__);
      Test::More::is($tc, 'AssertiveTestCase', 'Got correct TestCase');
      Test::More::like($test, qr'test_with_passing_\w+tion', 'Got correct test name');
    }
  }
}

push @ARGV, qw/ --logger SuccessLogger /;

{
  package AssertiveTestCase;
  use base 'MiniTest::Unit::TestCase';

  sub test_with_passing_assertion {
    Test::More::pass('Called ->test_with_passing_assertion');
    shift->assert(1)
  }

  sub test_with_passing_refutation {
    Test::More::pass('Called ->test_with_failing_refutation');
    shift->refute(0);
  }

  1;
}