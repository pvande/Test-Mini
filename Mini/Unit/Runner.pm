use MooseX::Declare;

class Mini::Unit::Runner {
  use aliased 'Mini::Unit::TestCase';
  use Mini::Unit::Logger::XUnit;
  use TryCatch;

  has logger => (
    is => 'rw',
    does => 'Mini::Unit::Logger',
    handles => [
      (map {
        (
          "begin_$_"  => "begin_$_",
          "finish_$_" => "finish_$_",
        )
      } qw/ test_suite test_case test /),
      pass  => 'pass',
      skip  => 'skip',
      fail  => 'fail',
      error => 'error',
    ],
  );

  has exit_code => ( is => 'rw', default => 1 );

  # class_has file => (
  #   is      => 'ro',
  #   default => sub { use Cwd 'abs_path'; abs_path(__FILE__); },
  # );

  method autorun(ClassName $class:)
  {
    END {
      $| = 1;
      return if $?;
      $? = !! $class->new()->run(@ARGV);
    }
  }

  method run(@args)
  {
    my $verbosity = grep { /-v+/ } @args;
    $self->logger(Mini::Unit::Logger::XUnit->new(verbose => $verbosity));
    $self->run_test_suite();
    return $self->exit_code();
  }

  method run_test_suite($filter? = qr/./)
  {
    for my $tc (TestCase->meta()->subclasses()) {
      my @tests = grep { /^test/ } $tc->meta()->get_all_method_names();
      $self->run_test_case($tc, grep { $filter } @tests);
    }
  }

  method run_test_case(ClassName $tc, @tests)
  {
    $self->run_test($tc, $_) for $self->sort_tests(@tests);
  }

  method run_test(ClassName $tc, Str $test)
  {
    my $instance = $tc->new(name => $test);
    return $instance->run($self);
  }

  method sort_tests(@tests)
  {
    # TODO: Allow tests to be randomly ordered
    @tests
  }


  around run_test_suite(@args) {
    $self->begin_test_suite(@args);
    my $retval = $self->$orig(@args);
    $self->finish_test_suite(@args, $retval);
  }

  around run_test_case(@args) {
    $self->begin_test_case(@args);
    my $retval = $self->$orig(@args);
    $self->finish_test_case(@args, $retval);
  }

  around run_test(@args) {
    $self->begin_test(@args);
    my $retval = $self->$orig(@args);
    $self->finish_test(@args, $retval);
  }

  before run_test($tc, $test)    { $self->exit_code(0) }
  after  fail($tc, $test, $msg)  { $self->exit_code(1) }
  after  error($tc, $test, $msg) { $self->exit_code(1) }
}
