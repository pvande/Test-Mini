package Test::Mini::Unit::Runner;
use strict;
use warnings;

use Getopt::Long;
use Try::Tiny;
use Class::MOP;
use aliased 'Test::Mini::Unit::TestCase';
use List::Util qw/ shuffle /;

sub new {
    my ($class, %args) = @_;

    my %argv = (
        verbose   => $ENV{TEST_MINI_VERBOSE} || 0,
        filter    => $ENV{TEST_MINI_FILTER}  || '',
        logger    => $ENV{TEST_MINI_LOGGER}  || 'Test::Mini::Logger::TAP',
        seed      => $ENV{TEST_MINI_SEED}    || int(rand(64_000_000)),
        exit_code => 0,
    );

    GetOptions(\%argv, qw/ verbose! filter=s logger=s seed=s /);
    return bless { %argv, %args }, $class;
}

sub verbose   { shift->{verbose}   }
sub filter    { shift->{filter}    }
sub logger    { shift->{logger}    }
sub seed      { shift->{seed}      }
sub exit_code { shift->{exit_code} }

sub run {
    my ($self) = @_;
    my $logger = $self->logger;
    try {
        Class::MOP::load_class($logger);
    }
    catch {
        $logger = "Test::Mini::Logger::$logger";
        Class::MOP::load_class($logger);
    };

    $logger = $logger->new(verbose => $self->verbose);
    $self->{logger} = $logger;

    srand($self->seed);

    return $self->run_test_suite(filter => $self->filter, seed => $self->seed);
}

sub run_test_suite {
    my ($self, %args) = @_;
    $self->logger->begin_test_suite(%args);

    my @testcases = @{ mro::get_isarev(TestCase) };
    $self->{exit_code} = 255 unless @testcases;

    for my $tc (shuffle @testcases) {
        no strict 'refs';
        my @tests = grep { /^test.+/ && defined &{"$tc\::$_"}} keys %{"$tc\::"};
        $self->run_test_case($tc, grep { $_ =~ qr/$args{filter}/ } @tests);
    }

    $self->logger->finish_test_case(%args, $self->exit_code);
    return $self->exit_code;
}

sub run_test_case {
    my ($self, $tc, @tests) = @_;
    $self->logger->begin_test_case($tc, @tests);

    $self->{exit_code} = 127 unless @tests;
    $self->run_test($tc, $_) for shuffle @tests;

    $self->logger->finish_test_case($tc, @tests);
}

sub run_test {
    my ($self, $tc, $test) = @_;
    $self->logger->begin_test($tc, $test);

    my $instance = $tc->new(name => $test);
    my $result = $instance->run($self);

    $self->logger->finish_test($tc, $test, $result);
    return $result;
}

sub pass {
    my ($self, $tc, $test) = @_;
    $self->logger->pass($tc, $test);
}

sub skip {
    my ($self, $tc, $test, $e) = @_;
    $self->logger->skip($tc, $test, $e);
}

sub fail {
    my ($self, $tc, $test, $e) = @_;
    $self->{exit_code} = 1 unless $self->{exit_code};
    $self->logger->fail($tc, $test, $e);
}

sub error {
    my ($self, $tc, $test, $e) = @_;
    $self->{exit_code} = 1 unless $self->{exit_code};
    $self->logger->error($tc, $test, $e);
}

1;
