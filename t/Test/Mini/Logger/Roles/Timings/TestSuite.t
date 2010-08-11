use Test::Mini::Unit;
namespace Test::Mini::Logger::Roles;

class MockLogger with ::Timings::TestSuite
{
  has start    => (is => 'rw');
  has stop     => (is => 'rw');
  has time_for => (is => 'rw');

  method begin_test_suite()  { }
  method finish_test_suite() { }
}

testcase ::Timings::TestSuite::Test
{
  has logger => (is => 'rw');

  setup { $self->logger(MockLogger->new()) }

  test begin_test_suite
  {
    $self->logger->begin_test_suite();

    assert defined($self->logger->start), '#start was not called with a valid key';
  }

  test finish_test_suite
  {
    $self->logger->finish_test_suite();

    assert defined($self->logger->stop), '#stop was not called with a valid key'
  }

  test total_time
  {
    $self->logger->begin_test_suite();
    $self->logger->finish_test_suite();
    $self->logger->total_time();

    assert_equal $self->logger->start, $self->logger->stop;
    assert_equal $self->logger->start, $self->logger->time_for();
  }
}