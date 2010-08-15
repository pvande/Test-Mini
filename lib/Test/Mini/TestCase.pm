package Test::Mini::TestCase;
use strict;
use warnings;

use Exception::Class;
use Test::Mini::Assertions;

{
    my $class = __PACKAGE__;
    no strict 'refs';
    *$class = \{ 'setup' => [], 'teardown' => [] };
}

sub new {
    my ($class, %args) = @_;
    return bless { passed => 0, %args }, $class;
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub passed {
    my ($self, $value) = @_;;
    return $self->{passed} if @_ % 2;
    $self->{passed} = $value;
}

sub setup {
    my ($self) = @_;
    no strict 'refs';
    for my $class (reverse @{ mro::get_linear_isa(ref $self) }) {
        $_->($self) for @{ ${"::$class"}->{setup} };
    }
}

sub teardown {
    my ($self) = @_;
    no strict 'refs';
    for my $class (@{ mro::get_linear_isa(ref $self) }) {
        $_->($self) for reverse @{ ${"::$class"}->{teardown} || [] };
    }
}

sub run {
    my ($self, $runner) = @_;
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

1;
