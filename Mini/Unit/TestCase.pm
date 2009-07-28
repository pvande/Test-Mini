use MooseX::Declare;

use Mini::Unit::Assertions;

class Mini::Unit::TestCase with Mini::Unit::Assertions {
  use TryCatch;
  has 'name' => (is => 'ro');
  has 'passed' => (is => 'rw', default => 0);

  method setup()    {}
  method teardown() {}

  method run($runner) {
    my $test = $self->name();

    try {
      $self->setup();
      $self->$test();
      $self->passed(1);
    }
    catch (Mini::Unit::Skip $e) {
      $self->passed(0);
      $runner->skip(ref $self, $test, $e->message());
    }
    catch (Mini::Unit::Assert $e) {
      $self->passed(0);
      $runner->fail(ref $self, $test, $e->message());
    }
    catch ($e) {
      # TODO: Ignore reasonable exceptions.
      $self->passed(0);
      $runner->error(ref $self, $test, $e);
    };

    try {
      $self->teardown();
      $runner->pass(__PACKAGE__, $self->name()) if $self->passed();
    }
    catch ($e) {
      # TODO: Ignore reasonable exceptions.
      $runner->error(ref $self, $test, $e);
    };
  }
}