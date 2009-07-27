use MooseX::Declare;

class Mini::Unit::Assert with Throwable {
  has 'message' => (is => 'ro');
  sub BUILDARGS { return shift->SUPER::BUILDARGS(message => join '', @_); }
}

class Mini::Unit::Skip extends Mini::Unit::Assert {}

role Mini::Unit::Assertions {
  use MooseX::AttributeHelpers;
  has _assertions => (
    metaclass => 'Number',
    is        => 'rw',
    isa       => 'Int',
    default   => 0,
    provides  => {
      add => '_add_assertions',
    },
  );

  method assert($test, $msg = "Failed assertion, no message given") {
    $self->_add_assertions(1);
    $msg = $msg->() if ref $msg eq 'CODE';
    Mini::Unit::Assert->throw($msg) unless $test;
  }
}

class Mini::Unit::TestCase with Mini::Unit::Assertions {
  use TryCatch;
  has 'name' => (is => 'ro');
  has 'passed' => (is => 'rw', default => 0);

  method setup()    {}
  method teardown() {}

  method run($runner) {
    my $test = $self->name();

    try {
      $self->setup();
      $self->$test();
      $self->passed(1);
    }
    catch (Mini::Unit::Skip $e) {
      $self->passed(0);
      $runner->skip(ref $self, $test, $e->message());
    }
    catch (Mini::Unit::Assert $e) {
      $self->passed(0);
      $runner->fail(ref $self, $test, $e->message());
    }
    catch ($e) {
      # TODO: Ignore reasonable exceptions.
      $self->passed(0);
      $runner->error(ref $self, $test, $e);
    };

    try {
      $self->teardown();
      $runner->pass(__PACKAGE__, $self->name()) if $self->passed();
    }
    catch ($e) {
      # TODO: Ignore reasonable exceptions.
      $runner->error(ref $self, $test, $e);
    };
  }
}

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

class Mini::Unit::Logger::Default {
  # TODO: Fix 'with' to work inside a class scope.
  Moose::with(__PACKAGE__, 'Mini::Unit::Logger');

  after begin_test_suite($filter?) {
    $self->print('Loaded Suite');
    $self->print(" (Filtered to /$filter/)") if $filter;
    $self->puts("\n")
  }

  after finish_test_suite($filter?) {
    $self->puts("\n", "Finished in @{[$self->total_time()]} seconds.");
  }

  after pass(ClassName $tc, Str $test) {
    my $result = $self->verbose() ? 'Passed!' : '.';
    $self->print($result);
  }

  after fail(ClassName $tc, Str $test, Str $msg) {
    my $result = $self->verbose() ? "Failed - $msg!" : 'F';
    $self->print($result);
  }

  after skip(ClassName $tc, Str $test, Str $msg) {
    my $result = $self->verbose() ? "Skipped - $msg!" : 'S';
    $self->print($result);
  }

  after error(ClassName $tc, Str $test, Str $msg) {
    my $result = $self->verbose() ? "ERROR - $msg" : 'E';
    $self->print($result);
  }
}

class Mini::Unit {
  use TryCatch;
  use MooseX::ClassAttribute;

  class_has logger => (
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
  class_has file => (
    is      => 'ro',
    default => sub { use Cwd 'abs_path'; abs_path(__FILE__); },
  );

  method autorun(ClassName $class:) {
    END {
      return if $?;
      $? = !! Mini::Unit->new()->run(@ARGV);
    }
  }

  method run(@args) {
    my $verbosity = grep { /-v+/ } @args;
    $self->logger(Mini::Unit::Logger::Default->new(verbose => $verbosity));

    $self->run_test_suite();

    return 0;
  }

  method run_test_suite($filter?) {
    for my $tc (Mini::Unit::TestCase->meta()->subclasses()) {
      my @tests = grep { /^test/ } $tc->meta()->get_all_method_names();
      $self->run_test_case($tc, grep { $filter || /./ } @tests);
    }
  }

  method run_test_case(ClassName $tc, @tests) {
    $self->run_test($tc, $_) for $self->sort_tests(@tests);
  }

  method run_test(ClassName $tc, Str $test) {
    $tc->new(name => $test)->run($self)
  }

  method sort_tests(@tests) {
    # TODO: Allow tests to be randomly ordered
    @tests
  }


  before run_test_suite($filter?) { $self->begin_test_suite($filter);  }
  after  run_test_suite($filter?) { $self->finish_test_suite($filter); }

  before run_test_case($tc, @tests) { $self->begin_test_case($tc, @tests);  }
  after  run_test_case($tc, @tests) { $self->finish_test_case($tc, @tests); }

  before run_test($tc, $test) { $self->begin_test($tc, $test);  }
  after  run_test($tc, $test) { $self->finish_test($tc, $test); }
}

Mini::Unit->autorun();

if ($0 eq __FILE__) {

  class TestCase extends Mini::Unit::TestCase {
    method test_pass {}
    method test_fail { $self->assert(0, 'Failed HARD!') }
    method test_skipped { Mini::Unit::Skip->throw('Skipped!') }
    method test_error { Mini::Unit::Foo->frobozz() }
  }

  use Data::Dumper;
  use Devel::Symdump;
  # print Devel::Symdump->new('Mini::Unit', 'Assertions')->as_string;
}

1;