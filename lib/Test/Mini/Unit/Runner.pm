use MooseX::Declare;

class Test::Mini::Unit::Runner {
  use Try::Tiny;
  use MooseX::Attribute::ENV;
  use aliased 'Test::Mini::Unit::TestCase';
  use List::Util qw/ shuffle /;

  with 'MooseX::Getopt';

  has 'verbose' => (
    traits     => ['ENV'],
    is         => 'rw',
    isa        => 'Bool',
    env_prefix => 'TEST_MINI',
    default    => 0,
  );

  has 'filter' => (
    traits     => ['ENV'],
    is         => 'rw',
    isa        => 'Str',
    env_prefix => 'TEST_MINI',
    default    => '',
  );

  has 'logger' => (
    traits     => ['ENV'],
    is         => 'rw',
    isa        => 'Str',
    env_prefix => 'TEST_MINI',
    default    => 'Test::Mini::Logger::TAP',
  );

  has 'seed' => (
    traits     => ['ENV'],
    is         => 'rw',
    isa        => 'Int',
    env_prefix => 'TEST_MINI',
    default    => int(rand(64_000_000)),
  );

  has '_logger' => (
    writer  => 'set_logger',
    isa     => 'Test::Mini::Logger',
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

  has '_exit_code' => (accessor => 'exit_code', default => 0);


  # class_has file => (
  #   is      => 'ro',
  #   default => sub { use Cwd 'abs_path'; abs_path(__FILE__); },
  # );

  method run
  {
    my $logger = $self->logger;
    try
    {
        Class::MOP::load_class($logger);
    }
    catch
    {
        $logger = "Test::Mini::Logger::$logger";
        Class::MOP::load_class($logger);
    };

    $logger = $logger->new(verbose => $self->verbose);
    $self->set_logger($logger);

    srand($self->seed);

    return $self->run_test_suite(filter => $self->filter, seed => $self->seed);
  }

  method run_test_suite(:$filter, :$seed)
  {
    my @testcases = TestCase->meta->subclasses;
    $self->exit_code(255) unless @testcases;

    for my $tc (shuffle @testcases) {
      my @tests = grep { /^test.+/ } $tc->meta->get_all_method_names();
      $self->run_test_case($tc, grep { qr/$filter/ } @tests);
    }

    return $self->exit_code;
  }

  method run_test_case(ClassName $tc, @tests)
  {
    $self->exit_code(127) unless @tests;
    $self->run_test($tc, $_) for shuffle @tests;
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
    return $retval;
  }

  around run_test_case(@args) {
    $self->begin_test_case(@args);
    my $retval = $self->$orig(@args);
    $self->finish_test_case(@args, $retval);
    return $retval;
  }

  around run_test(@args) {
    $self->begin_test(@args);
    my $retval = $self->$orig(@args);
    $self->finish_test(@args, $retval);
    return $retval;
  }

  after fail(@)  { $self->exit_code(1) unless $self->exit_code > 1 }
  after error(@) { $self->exit_code(1) unless $self->exit_code > 1 }
}
