use MooseX::Declare;

class MiniTest::Unit::Logger::TestRB is dirty
{
  with qw/
    MiniTest::Unit::Logger
    MiniTest::Unit::Logger::Roles::Timings
    MiniTest::Unit::Logger::Roles::Statistics
  /;

  sub clean_backtrace
  {
    my $error = shift;

    my @context = grep { ?? .. $_->package =~ /MiniTest::Unit::TestCase/ } $error->trace->frames();
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

  has 'result' => (is => 'rw', isa => 'Str');
  has 'report' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
      add_to_report => 'push',
    },
  );

  method begin_test_suite(:$filter, :$seed!)
  {
    $self->print('Loaded Suite');
    $self->print(" (Filtered to /$filter/)") if $filter;
    $self->say("\nSeeded with $seed\n");
  }

  # method begin_test(ClassName $tc, Str $test)
  # {
  #   $self->print("$tc#$test: ") if $self->verbose();
  # }
  # 
  # method finish_test(ClassName $tc, Str $test, @)
  # {
  #   $self->print("@{[ $self->time_for($tc, $test) ]} s: ") if $self->verbose();
  #   $self->print($self->result() || ());
  #   $self->say() if $self->verbose();
  # }
  # 
  # method finish_test_suite(@)
  # {
  #   $self->say() unless $self->verbose();
  #   $self->say('', "Finished in @{[$self->total_time()]} seconds.");
  # 
  #   my $i = 1;
  #   $self->say(sprintf("\n%3d) %s", $i++, $_)) for @{ $self->report() };
  # 
  #   $self->say();
  #   $self->say($self->statistics());
  # }
  # 
  # 
  # method pass(ClassName $tc, Str $test)
  # {
  #   $self->result('.');
  # }
  # 
  # method fail(ClassName $tc, Str $test, $e)
  # {
  #   $self->result('F');
  #   $self->add_to_report(
  #     sprintf(
  #       "Failure:\n%s(%s) [%s]:\n%s",
  #       $test,
  #       $tc,
  #       location($e),
  #       $e->message,
  #     )
  #   );
  # }
  # 
  # method skip(ClassName $tc, Str $test, $e)
  # {
  #   $self->result('S');
  #   $self->add_to_report(
  #     sprintf(
  #       "Skipped:\n%s(%s) [%s]:\n%s",
  #       $test,
  #       $tc,
  #       location($e),
  #       $e->message,
  #     )
  #   );
  # }
  # 
  # method error(ClassName $tc, Str $test, $e)
  # {
  #   my $msg = $e;
  #   if (ref $e) {
  #     my @trace = clean_backtrace($e);
  #     @trace = map { '  ' . $_->as_string } @trace; # TODO: Use friendlier @_ dump
  #     $msg = $e->message . join "\n", @trace;
  #   }
  # 
  #   $self->result('E');
  #   $self->add_to_report(
  #     sprintf(
  #       "Error:\n%s(%s):\n%s",
  #       $test,
  #       $tc,
  #       $msg,
  #     )
  #   );
  # }
}
