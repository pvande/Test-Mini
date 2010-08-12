use Test::Mini::Unit;
namespace Test::Mini::Logger::Roles;

class DummyLogger extends Test::Mini::Logger with ::Timings {}

testcase ::Timings::Test
{
  has logger => (is => 'rw');

  setup { $self->logger(DummyLogger->new()) }

  test start
  {
    my $time = $self->logger->start('Something');

    assert $time > 0, '$time should be greater than 0';
    assert_equal $time, $self->logger->started_at('Something');
  }

  test start_with_complex_key
  {
    my $time = $self->logger->start(qw/ a b c /);

    assert $time > 0, '$time should be greater than 0';
    assert_equal $time, $self->logger->started_at('a#b#c');
  }

  test stop
  {
    my $time = $self->logger->stop('Something');

    assert $time > 0, '$time should be greater than 0';
    assert_equal $time, $self->logger->ended_at('Something');
  }

  test stop_with_complex_key
  {
    my $time = $self->logger->stop(qw/ a b c /);

    assert $time > 0, '$time should be greater than 0';
    assert_equal $time, $self->logger->ended_at('a#b#c');
  }

  test time_for
  {
    my $start = $self->logger->start('Something');
    sleep 2;
    my $end = $self->logger->stop('Something');
    my $time = $end - $start;

    assert $time > 0, '$time should be greater than 1';
    assert_equal $time, $self->logger->time_for('Something');
  }

  test time_for_with_complex_key
  {
    my $start = $self->logger->start(qw/ a b c /);
    sleep 2;
    my $end = $self->logger->stop(qw/ a b c /);
    my $time = $end - $start;

    assert $time > 0, '$time should be greater than 1';
    assert_equal $time, $self->logger->time_for(qw/ a b c /);
  }
}