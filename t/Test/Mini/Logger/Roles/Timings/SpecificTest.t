use Test::Mini::Unit;
namespace Test::Mini::Logger::Roles;

class MyClass { }

class MockLogger with ::Timings::SpecificTest
{
  has _start => (
    is       => 'rw',
    traits   => ['Array'],
    default  => sub { [] },
    handles  => { start => 'push' },
  );
  has _stop => (
    is      => 'rw',
    traits  => ['Array'],
    default => sub { [] },
    handles => { stop  => 'push' },
  );

  method begin_test(@)  { }
  method finish_test(@) { }
}

testcase ::Timings::SpecificTest::Test
{
  has logger => (is => 'rw');

  setup { $self->logger(MockLogger->new()) }

  test begin_test
  {
    $self->logger->begin_test('MyClass', 'method_name');
    assert_equal ['MyClass', 'method_name'], $self->logger->_start;
  }

  test finish_test
  {
    $self->logger->finish_test('MyClass', 'method_name');
    assert_equal ['MyClass', 'method_name'], $self->logger->_stop;
  }
}