use MiniTest::Unit;

class MyClass { }

testcase MiniTest::Unit::Logger::Silent::Test
{
  use IO::Scalar;
  use aliased 'MiniTest::Unit::Logger::Silent' => 'SilentLogger';

  test full_test_run_should_remain_silent
  {
    my $logger = SilentLogger->new(
      buffer => my $buffer = IO::Scalar->new(),
    );

    $logger->begin_test_suite();
    $logger->begin_test_case('MyClass', qw/ method1 method2 method3 method4 /);
    $logger->begin_test('MyClass', 'method1');
    $logger->pass('MyClass', 'method1');
    $logger->finish_test('MyClass', 'method1', 1);
    $logger->begin_test('MyClass', 'method2');
    $logger->fail('MyClass', 'method2', 'failure message');
    $logger->finish_test('MyClass', 'method2', 2);
    $logger->begin_test('MyClass', 'method3');
    $logger->error('MyClass', 'method3', 'error message');
    $logger->finish_test('MyClass', 'method3', 3);
    $logger->begin_test('MyClass', 'method4');
    $logger->skip('MyClass', 'method4', 'reason');
    $logger->finish_test('MyClass', 'method4', 0);
    $logger->finish_test_case('MyClass', qw/ method1 method2 method3 method4 /);
    $logger->finish_test_suite(1);

    assert_equal '', "$buffer";
  }
}