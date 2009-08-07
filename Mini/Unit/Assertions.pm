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

# $SIG{'__DIE__'} = sub {
#   shift->rethrow() if ref $_[0];
#   chomp(my $m = shift);
#   CORE::die Mini::Unit::Error->new($m);
# };

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
    Mini::Unit::Assert->throw(message => $msg, ignore_package => __PACKAGE__) unless $test;
  }

  sub skip
  {
    my ($msg) = @_;
    $msg ||= 'Test skipped; no message given.';

    $msg = $msg->() if ref $msg eq 'CODE';
    Mini::Unit::Skip->throw(message => $msg, ignore_package => __PACKAGE__);
  }

  Moose::Exporter->setup_import_methods(
    as_is => [
      grep { /^(assert|refute|skip)/ } __PACKAGE__->meta->get_method_list(),
    ],
  );
}