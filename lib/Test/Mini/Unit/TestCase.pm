use MooseX::Declare;

# require Test::Mini::Assertions;

class Test::Mini::Unit::TestCase with Test::Mini::Assertions
{
  has 'name'   => (is => 'ro');
  has 'passed' => (is => 'rw', default => 0);

  method setup { }
  method teardown { }

  method run($runner)
  {
    my $e;
    my $test = $self->name();

    eval {
      local $SIG{__DIE__} = sub {
        package Test::Mini::Unit::SIGDIE;

        die $@ if UNIVERSAL::isa($@, 'Test::Mini::Unit::Error');

        (my $msg = "@_") =~ s/ at .*? line \d+\.\n$//;
        my $error = Test::Mini::Unit::Error->new(
          message        => "$msg\n",
          ignore_package => [qw/ Test::Mini::Unit::SIGDIE Carp /],
        );

        my $me = $error->trace->frame(0);
        if ($me->{subroutine} eq 'Test::Mini::Unit::TestCase::__ANON__') {
          $me->{subroutine} = 'die';
          $me->{args} = [ $msg ];
        }

        die $error;
      };

      $self->setup() if $self->can('setup');
      $self->$test();
      $self->passed(1);

      die 'No assertions called' unless $self->count_assertions();
    };
    if ($e = Exception::Class->caught()) {
      $self->passed(0);

      if ($e = Exception::Class->caught('Test::Mini::Unit::Skip')) {
        $runner->skip(ref $self, $test, $e);
      }
      elsif ($e = Exception::Class->caught('Test::Mini::Unit::Assert')) {
        $runner->fail(ref $self, $test, $e);
      }
      elsif ($e = Exception::Class->caught('Test::Mini::Unit::Error')) {
        $runner->error(ref $self, $test, $e);
      }
    }

    eval {
      $self->teardown() if $self->can('teardown');
      $runner->pass(ref $self, $self->name()) if $self->passed();
    };
    if ($e = Exception::Class->caught()) {
      $runner->error(ref $self, $test, $e);
    }

    return $self->count_assertions();
  }
}
