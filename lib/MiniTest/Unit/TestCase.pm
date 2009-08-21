use MooseX::Declare;

use MiniTest::Unit::Assertions;

class MiniTest::Unit::TestCase with MiniTest::Unit::Assertions
{
  has 'name'   => (is => 'ro');
  has 'passed' => (is => 'rw', default => 0);

  method run($runner)
  {
    my $e; my $error;
    my $test = $self->name();

    eval {
      local $SIG{__DIE__} = sub {
        package MiniTest::Unit::SIGDIE;
        (my $msg = join "\n",@_) =~ s/ at .*? line \d+\.\n$//;

        $error = MiniTest::Unit::Error->new(
          message        => "$msg\n",
          ignore_package => [qw/ MiniTest::Unit::SIGDIE Carp /],
        );

        my $me = $error->trace->frame(0);
        if ($me->{subroutine} eq 'MiniTest::Unit::TestCase::__ANON__') {
          $me->{subroutine} = 'die';
          $me->{args} = [ $msg ];
        }

        die @_;
      };

      $self->setup() if $self->can('setup');
      $self->$test();
      $self->passed(1);

      die 'No assertions called' unless $self->count_assertions();
    };
    if ($e = Exception::Class->caught()) {
      $self->passed(0);

      if ($e = Exception::Class->caught('MiniTest::Unit::Skip')) {
        $runner->skip(ref $self, $test, $e);
      }
      elsif ($e = Exception::Class->caught('MiniTest::Unit::Assert')) {
        $runner->fail(ref $self, $test, $e);
      }
      else {
        $runner->error(ref $self, $test, $error);
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