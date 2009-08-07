use MooseX::Declare;

class Mini::Unit::Logger::XUnit is dirty
{
  with qw/
    Mini::Unit::Logger
    Mini::Unit::Logger::Roles::Timings
    Mini::Unit::Logger::Roles::Statistics
  /;

  sub clean_backtrace
  {
    my $error = shift;

    my @context = grep { ?? .. $_->package =~ /Mini::Unit::TestCase/ } $error->trace->frames();
    pop @context;
    reset;

    return @context;
  }

  sub location
  {
    my @trace = clean_backtrace(@_);
    my $frame = $trace[0];
    return "@{[$frame->filename]}:@{[$frame->line]}"
  }

  clean;

  use MooseX::AttributeHelpers;

  has 'result' => ( is => 'rw', isa => 'Str' );
  has 'report' => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef',
    default   => sub { [] },
    provides  => {
      push => 'add_to_report',
    },
  );

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

  method finish_test(ClassName $tc, Str $test, @)
  {
    $self->print("@{[ $self->time_for($tc, $test) ]} s: ") if $self->verbose();
    $self->print($self->result() || ());
    $self->puts() if $self->verbose();
  }

  method finish_test_suite(@)
  {
    $self->puts() unless $self->verbose();
    $self->puts('', "Finished in @{[$self->total_time()]} seconds.");

    my $i = 1;
    $self->puts(sprintf("\n%3d) %s", $i++, $_)) for @{ $self->report() };

    $self->puts();
    $self->puts($self->statistics());
  }


  method pass(ClassName $tc, Str $test)
  {
    $self->result('.');
  }

  method fail(ClassName $tc, Str $test, $e)
  {
    $self->result('F');
    $self->add_to_report(
      sprintf(
        "Failure:\n%s(%s) [%s]:\n%s",
        $test,
        $tc,
        location($e),
        $e->message,
      )
    );
  }

  method skip(ClassName $tc, Str $test, $e)
  {
    $self->result('S');
    $self->add_to_report(
      sprintf(
        "Skipped:\n%s(%s) [%s]:\n%s",
        $test,
        $tc,
        location($e),
        $e->message,
      )
    );
  }

  method error(ClassName $tc, Str $test, $e)
  {
    my $msg = $e;
    if (ref $e) {
      my @trace = clean_backtrace($e);
      @trace = map { '  ' . $_->as_string } @trace; # TODO: Use friendlier @_ dump
      $msg = $e->message . join "\n", @trace;
    }

    $self->result('E');
    $self->add_to_report(
      sprintf(
        "Error:\n%s(%s):\n%s",
        $test,
        $tc,
        $msg,
      )
    );
  }
}