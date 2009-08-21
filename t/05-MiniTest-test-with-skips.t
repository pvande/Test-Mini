use Test::More tests => 7;

END   { is($?, 0, 'Exit code') };
BEGIN { use_ok('MiniTest::Unit') };

{
  use MooseX::Declare;

  class SkipLogger with MiniTest::Unit::Logger {
    method skip(ClassName $tc, Str $test, $msg) {
      Test::More::pass('Called ->skip on ' . __PACKAGE__);
      Test::More::is($tc, 'TruantTestCase', 'Got correct TestCase');
      Test::More::is($test, 'test_that_skips', 'Got correct test name');
      Test::More::like($msg, qr"School's boring", 'Got correct message');
    }
  }
}

push @ARGV, qw/ --logger SkipLogger /;

{
  package TruantTestCase;
  use base 'MiniTest::Unit::TestCase';

  sub test_that_skips {
    Test::More::pass('Called ->test_that_skips');
    shift->skip("School's boring");
  }

  1;
}