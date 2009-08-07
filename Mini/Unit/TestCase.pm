use MooseX::Declare;

use Mini::Unit::Assertions;

class Mini::Unit::TestCase
{
  has 'name'   => (is => 'ro');
  has 'passed' => (is => 'rw', default => 0);

  method run($runner)
  {
    my $e; my $error;
    my $test = $self->name();

    eval {
      local $SIG{__DIE__} = sub {
        package Mini::Unit::SIGDIE;
        (my $msg = join "\n",@_) =~ s/ at .*? line \d+\.\n$//;

        $error = Mini::Unit::Error->new(
          message        => "$msg\n",
          ignore_package => [qw/ Mini::Unit::SIGDIE Carp /],
        );

        my $me = $error->trace->frame(0);
        if ($me->{subroutine} eq 'Mini::Unit::TestCase::__ANON__') {
          $me->{subroutine} = 'die';
          $me->{args} = [ $msg ];
        }

        die @_;
      };

      $self->setup() if $self->can('setup');
      $self->$test();
      $self->passed(1);
    };
    if ($e = Exception::Class->caught()) {
      $self->passed(0);

      if ($e = Exception::Class->caught('Mini::Unit::Skip')) {
        $runner->skip(ref $self, $test, $e);
      }
      elsif ($e = Exception::Class->caught('Mini::Unit::Assert')) {
        $runner->fail(ref $self, $test, $e);
      }
      else {
        $runner->error(ref $self, $test, $error);
      }
    }

    eval {
      $self->teardown() if $self->can('teardown');
      $runner->pass(__PACKAGE__, $self->name()) if $self->passed();
    };
    if ($e = Exception::Class->caught()) {
      $runner->error(ref $self, $test, $e);
    }

    return $self->count_assertions();
  }
}