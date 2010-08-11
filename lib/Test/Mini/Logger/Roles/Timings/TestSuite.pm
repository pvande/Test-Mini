use MooseX::Declare;

role Test::Mini::Logger::Roles::Timings::TestSuite
{
  requires qw/
    begin_test_suite
    finish_test_suite
    time_for
  /;

  my $SUITE = '__SUITE__' . rand();

  before begin_test_suite(@)
  {
    $self->start($SUITE);
  }

  after finish_test_suite(@)
  {
    $self->stop($SUITE);
  }

  method total_time() { $self->time_for($SUITE) }
}
