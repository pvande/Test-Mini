use MooseX::Declare;

role Test::Mini::Logger::Roles::Timings::TestCase
{
  requires qw/
    begin_test_case
    finish_test_case
  /;

  before begin_test_case($tc, @)
  {
    $self->start($tc);
  }

  after finish_test_case($tc, @)
  {
    $self->stop($tc);
  }
}
