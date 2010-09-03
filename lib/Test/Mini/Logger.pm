package Test::Mini::Logger;
use strict;
use warnings;

use Time::HiRes;

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

sub verbose {
    my ($self) = @_;
    return $self->{verbose};
}

sub buffer {
    my ($self) = @_;
    return $self->{buffer};
}

sub count {
    my ($self, $key) = @_;
    return ($key ? $self->{count}->{$key} : $self->{count}) || 0;
}

sub print {
    my ($self, @msg) = @_;
    print { $self->buffer() } @msg;
}

sub say {
    my ($self, @msg) = @_;
    $self->print(join("\n", @msg), "\n");
}

sub begin_test_suite {
    my ($self) = @_;
    $self->{times}->{$self} = -Time::HiRes::time();
}

sub begin_test_case {
    my ($self, $tc) = @_;
    $self->{times}->{$tc} = -Time::HiRes::time();
}

sub begin_test {
    my ($self, $tc, $test) = @_;
    $self->{times}->{"$tc#$test"} = -Time::HiRes::time();
}

sub finish_test {
    my ($self, $tc, $test, $assertion_count) = @_;
    $self->{count}->{test}++;
    $self->{count}->{assertions} += $assertion_count;
    $self->{times}->{"$tc#$test"} += Time::HiRes::time();
}

sub finish_test_case {
    my ($self, $tc) = @_;
    $self->{count}->{test_case}++;
    $self->{times}->{$tc} += Time::HiRes::time();
}

sub finish_test_suite {
    my ($self) = @_;
    $self->{count}->{test_suite}++;
    $self->{times}->{$self} += Time::HiRes::time();
}

sub pass  { shift->{count}->{pass}++  }
sub fail  { shift->{count}->{fail}++  }
sub skip  { shift->{count}->{skip}++  }
sub error { shift->{count}->{error}++ }

sub time {
    my ($self) = @_;
    $self->{times}->{$_[-1]};
}

1;