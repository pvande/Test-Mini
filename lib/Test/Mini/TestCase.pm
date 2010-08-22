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

# Run the appropriate advice for the test.  'setup' advice should be run in
# declaration order, from the most distant ancestor to the most recent.
# 'teardown' advice is run from modernity to antiquity, but should be run in
# the reverse of declaration order.
#
# @param ['setup'|'teardown'] $type The advice type to run.
sub run_advice {
    my ($self, $type) = @_;

    no strict 'refs';

    my @methods = map { ${"::$_"}->{$type} } @{ mro::get_linear_isa(ref $self) };

    @methods = reverse @methods                 if $type eq 'setup';
    @methods = map { [ reverse @$_ ] } @methods if $type eq 'teardown';

    map { $_->($self) } @$_ for @methods;
}

use namespace::clean;

sub new {
    my ($class, %args) = @_;
    return bless { %args, passed => 0 }, $class;
}

sub setup {
    my ($self) = @_;
    &run_advice($self, 'setup');
}

sub teardown {
    my ($self) = @_;
    &run_advice($self, 'teardown');
}

sub run {
    my ($self, $runner) = @_;
    my $e;
    my $test = $self->{name};

    eval {
        local $SIG{__DIE__} = sub {
            package Test::Mini::SIGDIE;

            die $@ if UNIVERSAL::isa($@, 'Test::Mini::Exception');

            (my $msg = "@_") =~ s/ at .*? line \d+\.\n$//;
            my $error = Test::Mini::Exception->new(
                message        => "$msg\n",
                ignore_package => [qw/ Test::Mini::SIGDIE Carp /],
            );

            my $me = $error->trace->frame(0);
            if ($me->{subroutine} eq 'Test::Mini::TestCase::__ANON__') {
                $me->{subroutine} = 'die';
                $me->{args} = [ $msg ];
            }

            die $error;
        };

        $self->setup();
        $self->$test();
        $self->{passed} = 1;

        die 'No assertions called' unless $self->count_assertions();
    };

    if ($e = Exception::Class->caught()) {
        $self->{passed} = 0;

        if ($e = Exception::Class->caught('Test::Mini::Exception::Skip')) {
            $runner->skip(ref $self, $test, $e);
        }
        elsif ($e = Exception::Class->caught('Test::Mini::Exception::Assert')) {
            $runner->fail(ref $self, $test, $e);
        }
        elsif ($e = Exception::Class->caught('Test::Mini::Exception')) {
            $runner->error(ref $self, $test, $e);
        }
    }

    eval {
        $self->teardown();
        $runner->pass(ref $self, $self->{name}) if $self->{passed};
    };
    if ($e = Exception::Class->caught()) {
        $runner->error(ref $self, $test, $e);
    }

    return $self->count_assertions();
}

1;
