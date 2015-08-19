
package Test::Mini::Runner;
use 5.006;
use strict;
use warnings;

use Getopt::Long;
use Try::Tiny;
use MRO::Compat;
use Test::Mini::TestCase;
use List::Util qw/ shuffle /;

sub new {
    my ($class, %args) = @_;

    my %argv = (
        verbose   => $ENV{TEST_MINI_VERBOSE} || 0,
        filter    => $ENV{TEST_MINI_FILTER}  || '',
        logger    => $ENV{TEST_MINI_LOGGER}  || 'Test::Mini::Logger::TAP',
        seed      => $ENV{TEST_MINI_SEED}    || int(rand(64_000_000)),
    );

    GetOptions(\%argv, qw/ verbose=s filter=s logger=s seed=i /);
    return bless { %argv, %args, exit_code => 0 }, $class;
}

# @group Attribute Accessors

# @return Logger verbosity.
sub verbose {
    my $self = shift;
    return $self->{verbose};
}

# @return Test name filter.
sub filter {
    my $self = shift;
    return $self->{filter};
}

# @return Logger instance.
sub logger {
    my $self = shift;
    return $self->{logger};
}

# @return Randomness seed.
sub seed {
    my $self = shift;
    return $self->{seed};
}

# @return Exit code, representing the status of the test run.
sub exit_code {
    my $self = shift;
    return $self->{exit_code};
}

# @group Test Run Hooks

# Begins the test run.
# Loads and instantiates the test output logger, then dispatches to
# {#run_test_suite} (passing the {#filter} and {#seed}, as appropriate).
#
# @return The result of the {#run_test_suite} call.
sub run {
    my ($self) = @_;
    my $logger = $self->logger;
    try {
        eval "require $logger;" or die $@;
    }
    catch {
        eval "require Test::Mini::Logger::$logger;" or die $@;
    };

    $logger = $logger->new(verbose => $self->verbose);
    $self->{logger} = $logger;

    return $self->run_test_suite(filter => $self->filter, seed => $self->seed);
}

# Runs the test suite.
# Finds subclasses of {Test::Mini::TestCase}, and dispatches to
# {#run_test_case} with the name of each test case and a list test methods to
# be run.
#
# @param [Hash] %args
# @option %args [String] filter Test name filter.
# @option %args [String] seed Randomness seed.
# @return The value of {#exit_code}.
sub run_test_suite {
    my ($self, %args) = @_;
    $self->logger->begin_test_suite(%args);

    srand($args{seed});
    my @testcases = @{ mro::get_isarev('Test::Mini::TestCase') };

    # Since mro::get_isarev is guaranteed to never shrink, we should "double
    # check" our testcases, to make sure that they actually are *still*
    # subclasses of Test::Mini::TestCase.
    # @see http://search.cpan.org/dist/perl-5.12.2/ext/mro/mro.pm#mro::get_isarev($classname)
    @testcases = grep { $_->isa('Test::Mini::TestCase') } @testcases;

    $self->{exit_code} = 255 unless @testcases;

    for my $tc (shuffle @testcases) {
        no strict 'refs';
        my @tests = grep { /^test.+/ && defined &{"$tc\::$_"}} keys %{"$tc\::"};
        $self->run_test_case($tc, grep { $_ =~ qr/$args{filter}/ } @tests);
    }

    $self->logger->finish_test_suite($self->exit_code);
    return $self->exit_code;
}

# Runs tests in a test case.
#
# @param [Class] $tc The test case to run.
# @param [Array<String>] @tests A list of tests to be run.
sub run_test_case {
    my ($self, $tc, @tests) = @_;
    $self->logger->begin_test_case($tc, @tests);

    $self->{exit_code} = 127 unless @{[
        (@tests, grep { $_->isa($tc) } @{ mro::get_isarev($tc) })
    ]};

    $self->run_test($tc, $_) for shuffle @tests;

    $self->logger->finish_test_case($tc, @tests);
    return scalar @tests;
}

# Runs a specific test.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the test method to be run.
# @return [Integer] The number of assertions called by the test.
sub run_test {
    my ($self, $tc, $test) = @_;
    $self->logger->begin_test($tc, $test);

    my $instance = $tc->new(name => $test);
    my $assertions = $instance->run($self);

    $self->logger->finish_test($tc, $test, $assertions);
    return $assertions;
}

# @group Callbacks

# Callback for passing tests.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the passing test.
sub pass {
    my ($self, $tc, $test) = @_;
    $self->logger->pass($tc, $test);
}

# Callback for skipped tests.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the skipped test.
# @param [Test::Mini::Exception::Skip] $e The exception object.
sub skip {
    my ($self, $tc, $test, $e) = @_;
    $self->logger->skip($tc, $test, $e);
}

# Callback for failing tests.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the failed test.
# @param [Test::Mini::Exception::Assert] $e The exception object.
sub fail {
    my ($self, $tc, $test, $e) = @_;
    $self->{exit_code} = 1 unless $self->{exit_code};
    $self->logger->fail($tc, $test, $e);
}

# Callback for dying tests.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the test with an error.
# @param [Test::Mini::Exception] $e The exception object.
sub error {
    my ($self, $tc, $test, $e) = @_;
    $self->{exit_code} = 1 unless $self->{exit_code};
    $self->logger->error($tc, $test, $e);
}

1;

__END__

=head1 NAME

Test::Mini::Runner - default test runner for Test::Mini test cases

=head1 DESCRIPTION

This module is responsible for finding and running the appropriate tests,
setting up output logging, and returning an appropriate status code.
For those looking to write tests with this framework,
the points of note are as follows:

=over 4

=item * Tests are run automatically at process exit.

=item * All test cases (subclasses of {Test::Mini::TestCase}) that have been
loaded at that time will be considered.  This includes indirect
subclasses.

=item * Within each test case, all methods defined with a name matching
C</^test.+/> will be run.

=over 4

=item * Each test will run in its own test case instance.

=item * Tests will be run in random order.

=item * The C<setup()> method will be called before each test is run.

=item * The C<teardown()> will be called after each test is run.

=item * Inherited tests are I<not> run.

=back

=item * Tests may be run via
L<prove|https://metacpan.org/pod/distribution/Test-Harness/bin/prove>,
by loading (via C<use>, C<do> or C<require>)
the files into another script, or by simply executing a file containing a
test case in the Perl interpreter.

=over 4

=item * If you want to use a non-TAP output logger, C<prove> is not an option.

=back

=item * Options may be passed in either as command line options,
or as environment variables.

=over 4

=item * Environment variable names are prefixed with C<TEST_MINI_>.

=item * Valid options are:

=item * C<verbose> - Specifies the logger's verbosity.

=item * C<filter> - Only tests with names matching this pattern should be run.

=item * C<logger> - Specifies an alternate output logger class.

=item * C<seed> - Specifies a random number seed; used to specify repeatable
test orderings.

=back

=back


=head1 CLASS METHODS

=head2 new(%args)

Constructor.
Arguments may be provided explicitly to the constructor or implicitly via
either C<@ARGV> (parsed by L<Getopt::Long>) or environment variables
(C<TEST_MINI_$option>).

The following arguments are supported:

=over 4

=item verbose

Logger verbosity. Defaults to 0.

=item filter

Test name filter. Defaults to ''.

=item logger

Logger class name. Defaults to L<Test::Mini::Logger::TAP>.

=item seed

Randomness seed. Defaults to a random number C<E<lt> 64_000_000>.

=back


=head1 ATTRIBUTE ACCESSORS

=head2 exit_code

Returns the exit code, representing the status of the test run.

=head2 filter

Test name filter.

=head2 logger

Logger instance.

=head2 seed

Randomness seed.

=head2 verbose

Logger verbosity


=head1 TEST RUN HOOKS

=head2 run

Begins the test run.
Loads and instantiates the test output logger, then dispatches to
C<run_test_suite()> (passing the C<filter> and C<seed>, as appropriate).

Returns the result of the C<run_test_suite> call.


=head2 run_test($tc, $test)

Runs a specific test. Takes two arguments, which identify the test to run:

=over 4

=item C<$tc>

The test case owning the test method.

=item C<$test>

The name of the test method to be run.

=back

Returns the number of assertions called by the test.


=head2 run_test_suite(%args)

Runs the test suite.
Finds subclasses of L<Test::Mini::TestCase>,
and dispatches to C<run_test_case()> with the name of each test case
and a list test methods to be run.

Can be passed a hash of arguments; the following keys are understood:

=over 4

=item filter - test name filter.

=item seed - seed for the random number generator.

=back

Returns the value of C<exit_code()>.


=head1 CALLBACKS

=head2 error($tc, $test, $e)

Callback for dying tests. Takes three arguments:

=over 4

=item C<$tc> - the test case owning the test method.

=item C<$test> - the name of the failed test.

=item C<$e> - the exception object,
an instance of L<Test::Mini::Exception::Assert>.

=back


=head2 pass($tc, $test)

Callback for passing tests. Takes two arguments: C<$tc> is the test case
owning the test method, and C<$test> is the name of the passing test.


=head2 skip($tc, $test, $e)

Callback for skipped tests. The arguments are the same as those for
the C<error()> method, above.


=head1 SEE ALSO

L<Test::Mini>

=head1 REPOSITORY

L<https://github.com/pvande/Test-Mini>

=head1 AUTHOR

Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by
Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

