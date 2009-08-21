use Test::More tests => 7;

END   { $? = 0 if is($?, 1, 'Exit code') };
BEGIN { use_ok('MiniTest::Unit') };

{
  use MooseX::Declare;

  class ErrorLogger with MiniTest::Unit::Logger {
    method error(ClassName $tc, Str $test, $msg) {
      Test::More::pass('Called ->error on ' . __PACKAGE__);
      Test::More::is($tc, 'ReticentTestCase', 'Got correct TestCase');
      Test::More::is($test, 'test_with_no_assertions', 'Got correct test name');
      Test::More::like($msg, qr"No assertions called", 'Got correct message');
    }
  }
}

push @ARGV, qw/ --logger ErrorLogger /;

{
  package ReticentTestCase;
  use base 'MiniTest::Unit::TestCase';

  sub test_with_no_assertions {
    Test::More::pass('Called ->test_with_no_assertions');
  }

  1;
}