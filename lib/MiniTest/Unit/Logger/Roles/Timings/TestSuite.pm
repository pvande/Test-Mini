use MooseX::Declare;

role Mini::Unit::Logger::Roles::Timings::TestSuite
{
  requires qw/
    begin_test_suite
    finish_test_suite
  /;

  before begin_test_suite($foo?)
  {
    $self->start('__SUITE__');
  }

  after finish_test_suite($foo?)
  {
    $self->stop('__SUITE__');
  }

  method total_time() { $self->time_for('__SUITE__') }
}