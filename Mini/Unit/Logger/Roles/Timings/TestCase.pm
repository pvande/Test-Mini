use MooseX::Declare;

role Mini::Unit::Logger::Roles::Timings::TestCase
{
  requires qw/
    begin_test_case
    finish_test_case
  /;

  before begin_test_case(ClassName $tc, @tests)
  {
    $self->start($tc);
  }

  after finish_test_case(ClassName $tc, @tests)
  {
    $self->stop($tc);
  }
}