package Test::Mini::Unit::Sugar::Test;
use base 'Devel::Declare::Context::Simple';
use strict;
use warnings;

use Devel::Declare ();
use Sub::Name;

sub import {
    my ($class, %args) = @_;
    my $caller = $args{into} || caller;

    {
        no strict 'refs';
        *{"$caller\::test"} = sub (&) {};
    }

    my $ctx = $class->new();
    Devel::Declare->setup_for(
        $caller => { test => { const => sub { $ctx->parser(@_) } } }
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator;
    my $name = $self->strip_name;

    $self->inject_if_block($self->scope_injector_call());
    $self->inject_if_block('my $self = shift;');

    $self->install("test_$name");
}

sub install {
    my ($self, $name) = @_;
    $self->shadow($self->code_for($name));
}

sub code_for {
    my ($self, $name) = @_;

    my $pkg = $self->get_curstash_name;
    $name = join('::', $pkg, $name) unless ($name =~ /::/);

    return sub (&) {
        my $code = shift;
        no strict 'refs';
        *{$name} = subname $name => $code;
    };
}

1;
