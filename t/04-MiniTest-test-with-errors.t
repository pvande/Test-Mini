use Test::More tests => 7;

END   { $? = 0 if is($?, 1, 'Exit code') };
BEGIN { use_ok('MiniTest::Unit') };

{
  use MooseX::Declare;

  class ErrorLogger with MiniTest::Unit::Logger {
    method error(ClassName $tc, Str $test, $msg) {
      Test::More::pass('Called ->error on ' . __PACKAGE__);
      Test::More::is($tc, 'ErringTestCase', 'Got correct TestCase');
      Test::More::is($test, 'test_that_dies', 'Got correct test name');
      Test::More::like($msg, qr"I'm dying here!", 'Got correct message');
    }
  }
}

push @ARGV, qw/ --logger ErrorLogger /;

{
  package ErringTestCase;
  use base 'MiniTest::Unit::TestCase';

  sub test_that_dies {
    Test::More::pass('Called ->test_that_dies');
    die "I'm dying here!";
  }

  1;
}