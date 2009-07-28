use MooseX::Declare;

class Mini::Unit {
  use TryCatch;
  use Mini::Unit::Logger::XUnit;

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
      $? = !! Mini::Unit->new()->run(@ARGV);
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
    for my $tc (Mini::Unit::TestCase->meta()->subclasses()) {
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
    $instance->run($self);
    return $instance->assertion_count();
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

Mini::Unit->autorun();

if ($0 eq __FILE__) {

  class TestCase extends Mini::Unit::TestCase
  {
    method test_pass { $self->assert(1); $self->assert(1); sleep 1 }
    method test_fail { sleep 1; $self->assert(0, 'Failed HARD!') }
    method test_skipped { sleep 1; Mini::Unit::Skip->throw('Not Yet Implemented') }
    method test_error { sleep 1; die 'fooblibarioafr!'; Mini::Unit::Foo->frobozz() }
  }

  use Data::Dumper;
  use Devel::Symdump;
  # print Devel::Symdump->new('Mini::Unit', 'Assertions')->as_string;
}

1;