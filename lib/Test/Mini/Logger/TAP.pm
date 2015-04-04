# Default Test::Mini Output Logger.
package Test::Mini::Logger::TAP;
use base 'Test::Mini::Logger';
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(test_counter => 0, %args);
}

# @return [IO] Diagnostic output buffer.
sub diag_buffer {
    my ($self) = @_;
    return $self->{diag_buffer} if defined $self->{diag_buffer};
    return $self->{diag_buffer} = (
        $ENV{HARNESS_VERBOSE}
            ? $self->{buffer}
            : IO::Handle->new_from_fd(fileno(STDERR),'w')
    );
}

sub test_counter {
    my ($self) = @_;
    return $self->{test_counter};
}

sub inc_counter {
    my ($self) = @_;
    $self->{test_counter}++;
}

# Write output to the {#diag_buffer}.
# Lines will be prepended with '# ' and separate messages will have newlines
# appended.
#
# @param @msg The diagnostics to be printed.
sub diag {
    my ($self, @msgs) = @_;
    my $msg = join "\n", @msgs;
    $msg =~ s/^/# /mg;
    $self->diag_buffer->print($msg, "\n");
}

sub begin_test_case {
    my ($self, $tc, @tests) = @_;
    $self->diag("Test Case: $tc");
}

sub begin_test {
    my ($self) = @_;
    $self->inc_counter();
}

sub pass {
    my ($self, undef, $test) = @_;
    $self->say("ok @{[$self->test_counter]} - $test");
}

sub fail {
    my ($self, undef, $test, $msg) = @_;
    $self->say("not ok @{[$self->test_counter]} - $test");
    $self->diag($msg);
}

sub error {
    my ($self, undef, $test, $msg) = @_;
    $self->say("not ok @{[$self->test_counter]} - $test");
    $self->diag($msg);
}

sub skip {
    my ($self, undef, $test, $msg) = @_;
    $self->print("ok @{[$self->test_counter]} - $test # SKIP");

    if ($msg =~ /\n/) {
      $self->say();
      $self->diag($msg);
    } else {
      $self->say(": $msg");
    }
}

sub finish_test_suite {
    my ($self) = @_;
    $self->say("1..@{[$self->test_counter]}");
}

1;
