use MooseX::Declare;

role Mini::Unit::Logger {
  has _times  => (is => 'ro', default => sub { { starts => {}, ends => {} } });
  has verbose => (is => 'ro');

  method print(@msg) {
    print STDOUT @msg;
  }

  method puts(@msg) {
    print STDOUT (join("\n", @msg), "\n")
  }


  method _start(@keys) {
    $self->_times()->{starts}->{join '#', @keys} = time();
  }

  method _stop(@keys) {
    $self->_times()->{ends}->{join '#', @keys} = time();
  }

  method time_for(@keys) {
    my $times = $self->_times();
    my $key = join '#', @keys;
    my $start = $times->{starts}->{$key};
    my $end   = $times->{ends}->{$key} || time();
    return $end - $start;
  }

  method total_time() { $self->time_for('__SUITE__') }


  method begin_test_suite($filter?) {
    $self->_start('__SUITE__');
  }

  method begin_test_case(ClassName $tc, @tests) {
    $self->_start($tc);
  }

  method begin_test(ClassName $tc, Str $test) {
    $self->_start($tc, $test);
  }

  method finish_test(ClassName $tc, Str $test) {
    $self->_stop($tc, $test);
  }

  method finish_test_case(ClassName $tc, @tests) {
    $self->_stop($tc);
  }

  method finish_test_suite($filter?) {
    $self->_stop('__SUITE__');
  }


  method pass(ClassName $tc, Str $test)            { }
  method fail(ClassName $tc, Str $test, Str $msg)  { }
  method skip(ClassName $tc, Str $test, Str $msg)  { }
  method error(ClassName $tc, Str $test, Str $msg) { }
}