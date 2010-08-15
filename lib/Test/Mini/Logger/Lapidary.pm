package Test::Mini::Logger::Lapidary;
use base 'Test::Mini::Logger';
use strict;
use warnings;

sub new {
    my ($self, %args) = @_;
    return $self->SUPER::new(result => '', report => [], %args);
}

sub clean_backtrace {
    my $error = shift;

    my @context = grep { ?? .. $_->package =~ /Test::Mini::TestCase/ } $error->trace->frames();
    pop @context;
    reset;

    return @context;
}

sub location {
    my @trace = clean_backtrace(@_);
    my $frame = $trace[0];
    return "@{[$frame->filename]}:@{[$frame->line]}"
}

sub statistics {
    my ($self) = @_;
    return join(', ',
      "@{[$self->count('test')]} tests",
      "@{[$self->count('assertions')]} assertions",
      "@{[$self->count('fail')]} failures",
      "@{[$self->count('error')]} errors",
      "@{[$self->count('skip')]} skips",
    );
}

sub result {
    my ($self, $value) = @_;
    return $self->{result} unless defined $value;
    $self->{result} = $value;
}

sub report {
    my ($self) = @_;
    return $self->{report};
}

sub add_to_report {
    my ($self, $value) = @_;
    push @{$self->{report}}, $value;
}

sub begin_test_suite {
    my ($self, %args) = @_;
    $self->SUPER::begin_test_suite(%args);
    $self->print('Loaded Suite');
    $self->print(" (Filtered to /$args{filter}/)") if exists $args{filter};
    $self->say("\nSeeded with $args{seed}\n");
}

sub begin_test {
    my ($self, $tc, $test) = @_;
    $self->SUPER::begin_test($tc, $test);
    $self->print("$tc#$test: ") if $self->verbose();
}

sub finish_test {
    my ($self, $tc, $test, $assertion_count) = @_;
    $self->SUPER::finish_test($tc, $test, $assertion_count);
    $self->print("@{[ $self->time(qq($tc#$test)) ]} s: ") if $self->verbose();
    $self->print($self->result() || ());
    $self->say() if $self->verbose();
}

sub finish_test_suite {
    my ($self) = @_;
    $self->SUPER::finish_test_suite();
    $self->say() unless $self->verbose();
    $self->say('', "Finished in @{[ $self->time() ]} seconds.", '');

    my $i = 1;
    for my $item (@{ $self->report() }) {
      $self->say(sprintf("%3d) %s", $i++, $item));
      $self->say() unless $item =~ /\n$/;
    }

    $self->say($self->statistics());
}

sub pass {
    my ($self, @args) = @_;
    $self->SUPER::pass(@args);
    $self->result('.');
}

sub fail {
    my ($self, $tc, $test, $e) = @_;
    $self->SUPER::fail($tc, $test, $e);
    $self->result('F');
    $self->add_to_report(
        sprintf(
          "Failure:\n%s(%s) [%s]:\n%s",
            $test,
            $tc,
            location($e),
            $e->message,
        )
    );
}

sub skip {
    my ($self, $tc, $test, $e) = @_;
    $self->SUPER::skip($tc, $test, $e);
    $self->result('S');
    $self->add_to_report(
      sprintf(
        "Skipped:\n%s(%s) [%s]:\n%s",
        $test,
        $tc,
        location($e),
        $e->message,
      )
    );
}

sub error {
    my ($self, $tc, $test, $e) = @_;
    $self->SUPER::error($tc, $test, $e);
    my $msg = $e;
    if (ref $e) {
        my @trace = clean_backtrace($e);
        @trace = map { '  ' . $_->as_string } @trace; # TODO: Use friendlier @_ dump
        $msg = $e->message . join "\n", @trace;
    }
    else {
        $e .= "\n";
    }

    $self->result('E');
    $self->add_to_report(
        sprintf(
            "Error:\n%s(%s):\n%s",
            $test,
            $tc,
            $msg,
        )
    );
}

1;
