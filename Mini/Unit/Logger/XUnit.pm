use MooseX::Declare;

class Mini::Unit::Logger::XUnit {
  # TODO: Fix 'with' to work inside a class scope.
  Moose::with(__PACKAGE__, 'Mini::Unit::Logger');

  after begin_test_suite($filter?) {
    $self->print('Loaded Suite');
    $self->print(" (Filtered to /$filter/)") if $filter;
    $self->puts("\n")
  }

  after finish_test_suite($filter?) {
    $self->puts("\n", "Finished in @{[$self->total_time()]} seconds.");
  }

  after pass(ClassName $tc, Str $test) {
    my $result = $self->verbose() ? 'Passed!' : '.';
    $self->print($result);
  }

  after fail(ClassName $tc, Str $test, Str $msg) {
    my $result = $self->verbose() ? "Failed - $msg!" : 'F';
    $self->print($result);
  }

  after skip(ClassName $tc, Str $test, Str $msg) {
    my $result = $self->verbose() ? "Skipped - $msg!" : 'S';
    $self->print($result);
  }

  after error(ClassName $tc, Str $test, Str $msg) {
    my $result = $self->verbose() ? "ERROR - $msg" : 'E';
    $self->print($result);
  }
}