package Test::Mini::Logger::TAP;
use base 'Test::Mini::Logger';
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(test_counter => 0, %args);
}

sub test_counter {
    my ($self) = @_;
    return $self->{test_counter};
}

sub inc_counter {
    my ($self) = @_;
    $self->{test_counter}++;
}

sub reset_counter {
    my ($self) = @_;
    $self->{test_counter} = 0;
}

sub diag {
    my ($self, @msgs) = @_;
    my $msg = join "\n", @msgs;
    $msg =~ s/^/# /mg;
    $self->say($msg);
}

sub begin_test_case {
    my ($self, $tc, @tests) = @_;
    $self->say("1..@{[scalar @tests]}");
    $self->diag("Test Case: $tc");
    $self->reset_counter();
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

1;