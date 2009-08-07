use MooseX::Declare;

# class Mini::Unit::Error with Throwable {
#   use Devel::StackTrace;
#
#   has 'message' => (is => 'ro');
#   has 'backtrace' => (
#     is => 'ro',
#     default => sub {
#       my $trace = Devel::StackTrace->new(no_refs => 1);
#       my $start = sub { shift->package =~ /Mini::Unit::Assertions/ };
#       my $end   = sub { shift->package =~ /Mini::Unit::TestCase/ };
#       my @context = grep { $start->($_) .. $end->($_) } $trace->frames();
#       return [ @context[ 1 .. ($#context - 1) ] ];
#     }
#   );
#
#   sub BUILDARGS { return shift->SUPER::BUILDARGS(message => join '', @_); }
# }
# class Mini::Unit::Assert extends Mini::Unit::Error {}
# class Mini::Unit::Skip extends Mini::Unit::Error   {}

use Exception::Class
  'Mini::Unit::Error', => {  },
  'Mini::Unit::Assert' => { isa => 'Mini::Unit::Error' },
  'Mini::Unit::Skip'   => { isa => 'Mini::Unit::Assert' },
;

role Mini::Unit::Assertions {
  no warnings 'closure';

  requires 'run';

  my $assertion_count = 0;
  method count_assertions { return $assertion_count }
  after run(@) { $assertion_count = 0; }

  method assert($class: $test, $msg = 'Assertion failed; no message given.')
  {
    $assertion_count += 1;
    $msg = $msg->() if ref $msg eq 'CODE';

    Mini::Unit::Assert->throw(
      message        => $msg,
      ignore_package => [__PACKAGE__, 'Moose::Exporter'],
    ) unless $test;

    return 1;
  }

  method refute($class: $test, $message = 'Refutation failed; no message given.')
  {
    return not assert($class, !$test, $message);
  }

  method skip($class: $msg = 'Test skipped; no message given.')
  {
    $msg = $msg->() if ref $msg eq 'CODE';
    Mini::Unit::Skip->throw(
      message        => $msg,
      ignore_package => [__PACKAGE__, 'Moose::Exporter'],
    );
  }


  use Moose::Exporter;
  Moose::Exporter->setup_import_methods(
    with_caller => [
      grep { /^(assert|refute|skip)/ } __PACKAGE__->meta->get_method_list(),
    ],
  );
}