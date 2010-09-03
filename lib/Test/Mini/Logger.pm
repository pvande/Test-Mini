# This class acts as a base class for new output loggers.  Whether you're
# using a tool that expects output in a certain format, or you just long for
# the familiar look and feel of another testing framework, this is what you're
# looking for.
package Test::Mini::Logger;
use strict;
use warnings;

use Time::HiRes;

# Constructor.
sub new {
    my ($class, %args) = @_;
    return bless {
        verbose => 0,
        buffer  => *STDOUT{IO},
        count   => {},
        times   => {},
        %args,
    }, $class;
}

# @return Logger verbosity.
sub verbose {
    my ($self) = @_;
    return $self->{verbose};
}

# @return Output buffer.
sub buffer {
    my ($self) = @_;
    return $self->{buffer};
}

# @overload count()
#   @return [Hash] The count hash.
# @overload count($key)
#   @param $key A key in the count hash.
#   @return [Number] The value for the given key.
sub count {
    my ($self, $key) = @_;
    return ($key ? $self->{count}->{$key} : $self->{count}) || 0;
}

# @group Output Functions

# Write output to the {#buffer}.  Lines will be output without added newlines.
# @param @msg The message(s) to be printed.  Will be handled as per +print+.
sub print {
    my ($self, @msg) = @_;
    print { $self->buffer() } @msg;
}

# Write output to the {#buffer}.  Lines will be output with appended newlines.
# @param @msg The message(s) to be printed.  Newlines will be appended to each
# message, before being passed to {#print}.
sub say {
    my ($self, @msg) = @_;
    $self->print(join("\n", @msg), "\n");
}

# @group Callbacks

# Called before the test suite is run.
sub begin_test_suite {
    my ($self) = @_;
    $self->{times}->{$self} = -Time::HiRes::time();
}

# Called before each test case is run.
sub begin_test_case {
    my ($self, $tc) = @_;
    $self->{times}->{$tc} = -Time::HiRes::time();
}

# Called before each test is run.
sub begin_test {
    my ($self, $tc, $test) = @_;
    $self->{times}->{"$tc#$test"} = -Time::HiRes::time();
}

# Called after each test is run.
sub finish_test {
    my ($self, $tc, $test, $assertion_count) = @_;
    $self->{count}->{test}++;
    $self->{count}->{assert} += $assertion_count;
    $self->{times}->{"$tc#$test"} += Time::HiRes::time();
}

# Called after each test case is run.
sub finish_test_case {
    my ($self, $tc) = @_;
    $self->{count}->{test_case}++;
    $self->{times}->{$tc} += Time::HiRes::time();
}

# Called after each test suite is run.
sub finish_test_suite {
    my ($self) = @_;
    $self->{count}->{test_suite}++;
    $self->{times}->{$self} += Time::HiRes::time();
}

# @group Statistics

# @return The number of passing tests run.
sub pass {
    my $self = shift;
    return $self->{count}->{pass}++;
}

# @return The number of failing tests run.
sub fail {
    my $self = shift;
    $self->{count}->{fail}++;
}

# @return The number of skipped tests.
sub skip {
    my $self = shift;
    $self->{count}->{skip}++;
}

# @return The number of tests with errors.
sub error {
    my $self = shift;
    $self->{count}->{error}++;
}

# @param $key The key to look up timings for.  The commonly populated values
# are:
#   +$self+ :: Time for test suite
#   +"TestCase" :: Time for the test case
#   +"TestCase#test" :: Time for the given test
# @return The time taken by the given argument.
sub time {
    my ($self, $key) = @_;
    $self->{times}->{$key};
}

1;