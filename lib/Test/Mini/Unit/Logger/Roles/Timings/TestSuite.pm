use MooseX::Declare;

role Test::Mini::Unit::Logger::Roles::Timings::TestSuite
{
  requires qw/
    begin_test_suite
    finish_test_suite
  /;

  before begin_test_suite(@)
  {
    $self->start('__SUITE__');
  }

  after finish_test_suite(@)
  {
    $self->stop('__SUITE__');
  }

  method total_time() { $self->time_for('__SUITE__') }
}
