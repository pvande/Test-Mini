package Test::Mini::Unit::Sugar::Advice;
use base 'Devel::Declare::Context::Simple';
use strict;
use warnings;

use B::Hooks::EndOfScope;
use Devel::Declare ();
use Sub::Name;

sub import {
    my ($class, %args) = @_;
    die 'Test::Mini::Unit::Sugar::Advice requires a name argument!' unless $args{name};

    my $caller = $args{into} || caller;

    {
        no strict 'refs';
        *{"$caller\::$args{name}"} = sub (&) {};
        on_scope_end {
            no warnings;
            *{"$caller\::$args{name}"} = \&{"Test::Mini::TestCase::$args{name}"};
        }
    }

    my $ctx = $class->new();
    Devel::Declare->setup_for(
        $caller => { $args{name} => { const => sub { $ctx->parser(@_) } } }
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator;

    $self->inject_if_block($self->scope_injector_call());
    $self->inject_if_block('my $self = shift;');

    $self->install($self->{Declarator});
}

sub install {
    my ($self, $name) = @_;
    $self->shadow($self->code_for($name));
}

sub code_for {
    my ($self, $name) = @_;

    my $pkg = $self->get_curstash_name;
    return sub (&) {
        my $code = shift;
        no strict 'refs';
        push @{${"::$pkg"}->{$name}}, $code;
    };
}

1;
