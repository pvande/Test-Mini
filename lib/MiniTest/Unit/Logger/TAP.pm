use MooseX::Declare;

class MiniTest::Unit::Logger::TAP with MiniTest::Unit::Logger
{
  use MooseX::AttributeHelpers;

  has 'test_counter' => (
    metaclass => 'Counter',
    is        => 'rw',
    isa       => 'Int',
    default   => 0,
    provides  => {
      inc   => 'inc_counter',
      reset => 'reset_counter',
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
}