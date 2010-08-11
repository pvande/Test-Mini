use Test::Mini::Unit;
namespace Test::Mini::Logger::Roles;

class MockLogger with ::Statistics
{
  method finish_test(@) { }
  method fail()         { }
  method error()        { }
  method skip()         { }
}

testcase ::Timings::Test
{
  has logger => (is => 'rw');

  setup { $self->logger(MockLogger->new()) }

  test assertion_count
  {
    assert_equal 0, $self->logger->assertion_count;
    $self->logger->finish_test('SomeClass', 'method1', 1);
    assert_equal 1, $self->logger->assertion_count;
    $self->logger->finish_test('SomeClass', 'method2', 2);
    assert_equal 3, $self->logger->assertion_count;
  }

  test test_count
  {
    assert_equal 0, $self->logger->test_count;
    $self->logger->finish_test('SomeClass', 'method1', 1);
    assert_equal 1, $self->logger->test_count;
    $self->logger->finish_test('SomeClass', 'method3', 4);
    assert_equal 2, $self->logger->test_count;
  }

  test failure_count
  {
    assert_equal 0, $self->logger->failure_count;
    $self->logger->fail();
    assert_equal 1, $self->logger->failure_count;
    $self->logger->fail();
    assert_equal 2, $self->logger->failure_count;
  }

  test error_count
  {
    assert_equal 0, $self->logger->error_count;
    $self->logger->error();
    assert_equal 1, $self->logger->error_count;
    $self->logger->error();
    assert_equal 2, $self->logger->error_count;
  }

  test skip_count
  {
    assert_equal 0, $self->logger->skip_count;
    $self->logger->skip();
    assert_equal 1, $self->logger->skip_count;
    $self->logger->skip();
    assert_equal 2, $self->logger->skip_count;
  }
}