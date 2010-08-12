use MooseX::Declare;

class Test::Mini::Logger::TAP
    extends Test::Mini::Logger
{
  has 'test_counter' => (
    traits  => [ 'Counter' ],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
      inc_counter   => 'inc',
      reset_counter => 'reset',
    },
  );

  method diag(@msgs)
  {
    my $msg = join "\n", @msgs;
    $msg =~ s/^/# /mg;
    $self->say($msg);
  }

  method begin_test_case(ClassName $tc, @tests)
  {
    $self->say("1..@{[scalar @tests]}");
    $self->diag("Test Case: $tc");
    $self->reset_counter();
  }

  method begin_test(@)
  {
    $self->inc_counter();
  }

  method pass(ClassName $tc, $test)
  {
    $self->say("ok @{[$self->test_counter]} - $test");
  }

  method fail(ClassName $tc, $test, $msg)
  {
    $self->say("not ok @{[$self->test_counter]} - $test");
    $self->diag($msg);
  }

  method error(ClassName $tc, $test, $msg)
  {
    $self->say("not ok @{[$self->test_counter]} - $test");
    $self->diag($msg);
  }

  method skip(ClassName $tc, $test, $msg)
  {
    $self->print("ok @{[$self->test_counter]} - $test # SKIP");
    if ($msg =~ /\n/) {
      $self->say();
      $self->diag($msg);
    } else {
      $self->say(": $msg");
    }
  }
}
