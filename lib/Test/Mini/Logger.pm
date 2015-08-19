package Test::Mini::Logger;

use 5.006;
use strict;
use warnings;

use Time::HiRes;

sub new {
    my ($class, %args) = @_;
    return bless {
        verbose => 0,
        buffer  => *STDOUT{IO},
        %args,
        count   => {},
        times   => {},
    }, $class;
}

# ===========================
# Attribute Accessors
# ===========================

sub verbose {
    my ($self) = @_;
    return $self->{verbose};
}

sub buffer {
    my ($self) = @_;
    return $self->{buffer};
}

# ===========================
# Output Functions
# ===========================

sub print {
    my ($self, @msg) = @_;
    print { $self->buffer() } @msg;
}

sub say {
    my ($self, @msg) = @_;
    $self->print(join("\n", @msg), "\n");
}

# ===========================
# Callbacks
# ===========================

# Called before the test suite is run.
sub begin_test_suite {
    my ($self, %args) = @_;
    $self->{times}->{$self} = -Time::HiRes::time();
}

# Called before each test case is run.
sub begin_test_case {
    my ($self, $tc, @tests) = @_;
    $self->{times}->{$tc} = -Time::HiRes::time();
}

# Called before each test is run.
sub begin_test {
    my ($self, $tc, $test) = @_;
    $self->{times}->{"$tc#$test"} = -Time::HiRes::time();
}

# Called after each test is run.
sub finish_test {
    my ($self, $tc, $test, $assertions) = @_;
    $self->{count}->{test}++;
    $self->{count}->{assert} += $assertions;
    $self->{times}->{"$tc#$test"} += Time::HiRes::time();
}

# Called after each test case is run.
sub finish_test_case {
    my ($self, $tc, @tests) = @_;
    $self->{count}->{test_case}++;
    $self->{times}->{$tc} += Time::HiRes::time();
}

# Called after each test suite is run.
sub finish_test_suite {
    my ($self, $exit_code) = @_;
    $self->{times}->{$self} += Time::HiRes::time();
}

# Called when a test passes.
sub pass {
    my ($self, $tc, $test) = @_;
    $self->{count}->{pass}++;
}

# Called when a test is skipped.
sub skip {
    my ($self, $tc, $test, $e) = @_;
    $self->{count}->{skip}++;
}

# Called when a test fails.
sub fail {
    my ($self, $tc, $test, $e) = @_;
    $self->{count}->{fail}++;
}

# Called when a test dies with an error.
sub error {
    my ($self, $tc, $test, $e) = @_;
    $self->{count}->{error}++;
}

# ===========================
# Statistics
# ===========================

# Accessor for counters.
sub count {
    my ($self, $key) = @_;
    return ($key ? $self->{count}->{$key} : $self->{count}) || 0;
}

# Accessor for the timing data.
sub time {
    my ($self, $key) = @_;
    return $self->{times}->{$key};
}

1;

__END__

=head1 NAME

Test::Mini::Logger - output logger base class for Test::Mini

=head1 DESCRIPTION

This module is the base class for loggers that are going to be
used with L<Test::Mini>. By default, C<Test::Mini> uses this
class directly, but you can subclass it and ask C<Test::Mini>
to use your class instead.


=head1 CLASS METHODS

=head2 new(%args)

Constructor. Takes a hash of arguments providing initial state.
Valid keys are:

=over 4

=item verbose - logger verbosity, defaulting to 0

=item buffer - output buffer, defaults to STDOUT.

=back


=head1 ATTRIBUTE ACCESSORS

=head2 buffer

Returns the output buffer.

=head2 verbose

Returns logger verbosity.


=head1 OUTPUT METHODS

=head2 print(@msg)

Write output to the C<buffer>.
Takes an array of strings, which will be output to C<buffer> without
adding any newlines.

=head2 say(@msg)

Writes output, adding a newline character to each entry in C<@msg>.


=head1 CALLBACKS

=head2 begin_test($tc, $test)

Called before each test is run.
C<$tc> is the test case owning the test method,
and C<$test> is the name of the test method being run.

=head2 begin_test_case($tc, @tests)

Called before each test case is run.
C<$tc> is the test case being run, and C<@tests> is a list of tests
to be run.

=head2 begin_test_suite(%args)

Called before the test suite is run. Takes a hash of arguments,
valid keys for which are:

=over 4

=item filter - test name filter.

=item seed - seed for the random number generator.

=back


=head2 error($tc, $test, $e)

Called when a test dies with an error. Increments the error count.
Takes three arguments:

=over 4

=item $tc - the test case owning the test method.

=item $test - the name of the test with an error.

=item $e - the exception object, an instance of L<Test::Mini::Exception>.

=back


=head2 fail($tc, $test, $e)

Called when a test fails. Increments the failure count.
Takes the same three arguments as C<error()>, above.


=head2 finish_test($tc, $test, $assertions)

Called after each test is run.
Increments the test and assertion counts, and finalizes the test's timing.
Takes three parameters:

=over 4

=item $tc -- The test case owning the test method.

=item $test -- The name of the test method just run.

=item $assertions -- The number of assertions called.

=back


=head2 finish_test_case($tc, @tests)

Called after each test case is run.
Increments the test case count, and finalizes the test case's timing.
Takes two arguments:

=over 4

=item $tc - the test case just run.

=item @tests - a list of tests run.

=back


=head2 finish_test_suite($exit_code)

Called after each test suite is run. Finalizes the test suite timing.
Takes one argument, which is the C<$exit_code> that the tests finished with.


=head2 pass($tc, $test)

Called when a test passes. Increments the pass count.
Takes two arguments:

=over 4

=item $tc - the test case owning the test method.

=item $test - the name of the passing test.

=back


=head2 skip($tc, $test, $e)

Called when a test is skipped. Increments the skip count.
Takes the same three arguments as the C<error()> method,
described above.


=head1 STATISTICS

=head2 count

If called with no arguments, this returns the hash of all counters.
If you pass the name of one test, it returns just the count for
the named test.

=head2 time($key)

Used to retrieve timing data for a test suite, test case, or specific test.
You can pass one of three argument types:

=over 4

=item $self - returns the time for the test suite.

=item "TestCase" - returns time for the test case.

=item "TestCase#test" - returns time for the given test in the test case.

=back

Times for units that have not finished should not be relied upon.

Returns the time taken by the given argument, in seconds.

=head1 SEE ALSO

L<Test::Mini>

=head1 REPOSITORY

L<https://github.com/pvande/Test-Mini>

=head1 AUTHOR

Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010
by Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

