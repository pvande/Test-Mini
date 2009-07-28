use MooseX::Declare;

role Mini::Unit::Logger is dirty
{
  has verbose => (is => 'ro');

  method print(@msg)
  {
    print STDOUT @msg;
  }

  method puts(@msg)
  {
    print STDOUT (join("\n", @msg), "\n")
  }

  clean;

  method begin_test_suite(@)  { }
  method begin_test_case(@)   { }
  method begin_test(@)        { }
  method finish_test(@)       { }
  method finish_test_case(@)  { }
  method finish_test_suite(@) { }

  method pass(ClassName $tc, Str $test)            { }
  method fail(ClassName $tc, Str $test, Str $msg)  { }
  method skip(ClassName $tc, Str $test, Str $msg)  { }
  method error(ClassName $tc, Str $test, Str $msg) { }
}