use Test::Mini::Unit;
namespace Test::Mini::Logger::Roles;

class MyClass { }

class MockLogger with ::Timings::TestCase
{
  has start => (is => 'rw');
  has stop  => (is => 'rw');

  method begin_test_case(@)  { }
  method finish_test_case(@) { }
}

testcase ::Timings::TestCase::Test
{
  has logger => (is => 'rw');

  setup { $self->logger(MockLogger->new()) }

  test begin_test_case
  {
    $self->logger->begin_test_case('MyClass');
    assert_equal 'MyClass', $self->logger->start;
  }

  test finish_test_case
  {
    $self->logger->finish_test_case('MyClass');
    assert_equal 'MyClass', $self->logger->stop;
  }
}