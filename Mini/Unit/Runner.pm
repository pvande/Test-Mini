use MooseX::Declare;

class Mini::Unit::Runner {
  use TryCatch;

  with 'MooseX::Getopt';
  has 'verbose' => (is => 'rw', isa => 'Bool', default => 0);
  has 'filter'  => (is => 'rw', isa => 'Str', default => '');
  has 'logger'  => (is => 'rw', isa => 'Str', default => 'Mini::Unit::Logger::XUnit');
  has 'seed'    => (is => 'rw', isa => 'Int', default => int(rand(64_000_000)));

  has '_logger' => (
    writer => 'set_logger',
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

  has '_exit_code' => (accessor => 'exit_code', default => 1);


  # class_has file => (
  #   is      => 'ro',
  #   default => sub { use Cwd 'abs_path'; abs_path(__FILE__); },
  # );

  method run
  {
    Class::MOP::load_class($self->logger);
    my $logger = $self->logger->new(runner => $self, verbose => $self->verbose);
    $self->set_logger($logger);

    srand($self->seed);

    return $self->run_test_suite();
  }

  method run_test_suite()
  {
    my @testcases = Mini::Unit::TestCase->meta->subclasses;
    for my $tc ($self->randomize(@testcases)) {
      my @tests = grep { /^test.+/ } $tc->meta->get_all_method_names();
      $self->run_test_case($tc, grep { qr/^test_@{[$self->filter]}/ } @tests);
    }

    return $self->exit_code;
  }

  method run_test_case(ClassName $tc, @tests)
  {
    $self->run_test($tc, $_) for $self->randomize(@tests);
  }

  method run_test(ClassName $tc, Str $test)
  {
    my $instance = $tc->new(name => $test);
    return $instance->run($self);
  }

  method randomize(@list)
  {
    return sort { int(rand(3)) - 1 } @list;
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
  after  fail(@)  { $self->exit_code(1) }
  after  error(@) { $self->exit_code(1) }
}
