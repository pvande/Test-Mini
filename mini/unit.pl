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
    my $result;

    try {
      my $test = $self->name();
      $self->setup();
      $self->$test();
      $self->passed(1);
    } catch ($e) {
      # TODO: Ignore reasonable exceptions.
      $self->passed(0);
      $runner->puke(__PACKAGE__, $self->name(), $e);
    };

    try {
      $self->teardown();
      $runner->pass(__PACKAGE__, $self->name()) if $self->passed();
    } catch ($e) {
      # TODO: Ignore reasonable exceptions.
      $runner->puke(__PACKAGE__, $self->name(), $e);
    };
  }
}

role Mini::Unit::Logger {
  has verbose     => (is => 'ro');
  has _begin_time => (is => 'rw');
  has _start_time => (is => 'rw');

  method print(@msg) {
    print STDOUT @msg;
  }

  method puts(@msg) {
    print STDOUT (join("\n", @msg), "\n")
  }

  method begin() {
    $self->puts("Loaded Suite\n");
    $self->_begin_time(time());
  }

  method start_test(ClassName $suite, Str $test) {
    $self->print("$suite#$test: ") if $self->verbose();
    $self->_start_time(time());
  }

  method pass(ClassName $suite, Str $test) {
    my $result = $self->verbose() ? 'Passed!' : '.';
    $self->print($result);
  }

  method fail(ClassName $suite, Str $test, Str $msg) {
    my $result = $self->verbose() ? "Failed - $msg!" : 'F';
    $self->print($result);
  }

  method skip(ClassName $suite, Str $test, Str $msg) {
    my $result = $self->verbose() ? "Skipped - $msg!" : 'S';
    $self->print($result);
  }

  method error(ClassName $suite, Str $test, Str $msg) {
    my $result = $self->verbose() ? "ERROR - $msg" : 'E';
    $self->print($result);
  }

  method end_test(ClassName $suite, Str $test) {
    $self->puts() if $self->verbose();
  }

  method finish() {
    my $time = time() - $self->_begin_time();
    $self->puts();
    $self->puts("Finished in $time seconds.");
  }
}

class Mini::Unit::Logger::Default with Mini::Unit::Logger {

}

class Mini::Unit {
  use TryCatch;
  use MooseX::ClassAttribute;

  class_has logger => (
    is => 'rw',
    does => 'Mini::Unit::Logger',
    handles => [
      begin      => 'begin',
      start_test => 'start_test',
      pass       => 'pass',
      skip       => 'skip',
      fail       => 'fail',
      error      => 'error',
      end_test   => 'end_test',
      finish     => 'finish,'
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

  method puke(ClassName $suite, Str $test, $err) {
    try {
      die $err;
    } catch (Mini::Unit::Skip $e) {
      $self->skip($suite, $test, $e->message());
    } catch (Mini::Unit::Assert $e) {
      $self->fail($suite, $test, $e->message());
    } catch {
      chomp($err);
      $self->error($suite, $test, $err);
    }
  }

  method run(@args) {
    my $verbosity = grep { /-v+/ } @args;
    $self->logger(Mini::Unit::Logger::Default->new(verbose => $verbosity));

    $self->begin();
    $self->run_test_suites();
    $self->finish();

    return 0;
  }

  method run_test_suites($filter?) {
    for my $suite (Mini::Unit::TestCase->meta()->subclasses()) {
      my @tests = grep { /^test/ } $suite->meta()->get_all_method_names();
      @tests = $self->sort_tests(@tests);
      for my $test (grep { $filter || /./ } @tests) {
        my $instance = $suite->new(name => $test);

        $self->logger()->start_test($suite, $test);
        $instance->run($self);
        $self->logger()->end_test($suite, $test);
      }
    }
  }

  method sort_tests(@tests) {
    # TODO: Allow tests to be randomly ordered
    @tests
  }
}

Mini::Unit->autorun();

if ($0 eq __FILE__) {

  class TestSuite extends Mini::Unit::TestCase {
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