use MooseX::Declare;

class Mini::Unit::Assert with Throwable {
  has 'message' => (is => 'ro');
  sub BUILDARGS { return shift->SUPER::BUILDARGS(message => join '', @_); }
}

class Mini::Unit::Skip extends Mini::Unit::Assert {}

role Mini::Unit::Assertions {
  use Moose::Exporter;
  no warnings 'closure';

  requires 'run';

  my $assertion_count = 0;
  method count_assertions { return $assertion_count }
  after run(@) { $assertion_count = 0; }

  sub assert
  {
    my ($test, $msg) = @_;
    $msg ||= 'Assertion failed; no message given.';

    $assertion_count += 1;
    $msg = $msg->() if ref $msg eq 'CODE';
    Mini::Unit::Assert->throw($msg) unless $test;
  }

  Moose::Exporter->setup_import_methods(
    as_is => [ grep { /^(assert|refute)/ } __PACKAGE__->meta->get_method_list() ],
  );
}