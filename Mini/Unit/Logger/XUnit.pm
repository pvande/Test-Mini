use MooseX::Declare;

class Mini::Unit::Logger::XUnit is mutable
{
  with qw/
    Mini::Unit::Logger
    Mini::Unit::Logger::Roles::Timings
  /;

  has 'result' => ( is => 'rw', isa => 'Str' );

  method begin_test_suite($filter?)
  {
    $self->print('Loaded Suite');
    $self->print(" (Filtered to /$filter/)") if $filter;
    $self->puts("\n");
  }

  method begin_test(ClassName $tc, Str $test)
  {
    $self->print("$tc#$test: ") if $self->verbose();
  }

  method finish_test(ClassName $tc, Str $test)
  {
    $self->print("@{[ $self->time_for($tc, $test) ]} s: ") if $self->verbose();
    $self->print($self->result());
    $self->puts() if $self->verbose();
  }

  method finish_test_suite($filter?)
  {
    $self->puts("\n", "Finished in @{[$self->total_time()]} seconds.");
  }


  method pass(ClassName $tc, Str $test)
  {
    $self->result($self->verbose() ? 'Passed!' : '.');
  }

  method fail(ClassName $tc, Str $test, Str $msg)
  {
    $self->result($self->verbose() ? "Failed - $msg!" : 'F');
  }

  method skip(ClassName $tc, Str $test, Str $msg)
  {
    $self->result($self->verbose() ? "Skipped - $msg!" : 'S');
  }

  method error(ClassName $tc, Str $test, Str $msg)
  {
    $self->result($self->verbose() ? "ERROR - $msg" : 'E');
  }
}