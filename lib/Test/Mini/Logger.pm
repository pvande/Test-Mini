use MooseX::Declare;

class Test::Mini::Logger is dirty
{
  has 'verbose' => (is => 'ro', default => 0);
  has 'buffer'  => (is => 'ro', default => sub { *STDOUT{IO} });

  method print(@msg)
  {
    print { $self->buffer() } @msg;
  }

  method say(@msg)
  {
    $self->print(join("\n", @msg), "\n")
  }

  clean;

  method begin_test_suite(@)  { }
  method begin_test_case(@)   { }
  method begin_test(@)        { }
  method finish_test(@)       { }
  method finish_test_case(@)  { }
  method finish_test_suite(@) { }

  method pass(ClassName $tc, Str $test)        { }
  method fail(ClassName $tc, Str $test, $msg)  { }
  method skip(ClassName $tc, Str $test, $msg)  { }
  method error(ClassName $tc, Str $test, $msg) { }
}
