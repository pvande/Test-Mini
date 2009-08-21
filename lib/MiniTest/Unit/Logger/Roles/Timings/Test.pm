use MooseX::Declare;

role Mini::Unit::Logger::Roles::Timings::Test
{
  requires qw/
    begin_test
    finish_test
  /;

  before begin_test($tc, $test, @)
  {
    $self->start("$tc#$test");
  }

  after finish_test($tc, $test, @)
  {
    $self->stop("$tc#$test");
  }
}