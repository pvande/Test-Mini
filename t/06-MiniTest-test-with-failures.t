use Test::More tests => 12;

END   { $? = 0 if is($?, 1, 'Exit code') };
BEGIN { use_ok('MiniTest::Unit') };

{
  use MooseX::Declare;

  class FailureLogger with MiniTest::Unit::Logger {
    method fail(ClassName $tc, Str $test, $msg) {
      Test::More::pass('Called ->fail on ' . __PACKAGE__);
      Test::More::is($tc, 'FallibleTestCase', 'Got correct TestCase');
      Test::More::like($test, qr'test_with_failing_\w+tion', 'Got correct test name');
      Test::More::like($msg, qr"\w+tion failed; no message given", 'Got correct message');
    }
  }
}

push @ARGV, qw/ --logger FailureLogger /;

{
  package FallibleTestCase;
  use base 'MiniTest::Unit::TestCase';

  sub test_with_failing_assertion {
    Test::More::pass('Called ->test_with_failing_assertion');
    shift->assert(0);
  }

  sub test_with_failing_refutation {
    Test::More::pass('Called ->test_with_failing_refutation');
    shift->refute(1);
  }

  1;
}