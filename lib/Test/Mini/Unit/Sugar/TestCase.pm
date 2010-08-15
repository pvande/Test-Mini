package Test::Mini::Unit::Sugar::TestCase;
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
        *{"$caller\::testcase"} = sub (&) {};
    }

    my $ctx = $class->new();
    Devel::Declare->setup_for(
        $caller => { testcase => { const => sub { $ctx->parser(@_) } } }
    );
}

sub code_for {
    my ($self, $name) = @_;

    my $pkg = $self->get_curstash_name;
    $name = join('::', $pkg, $name) unless ($name =~ /::/);
    return sub (&) {
        my $code = shift;
        no strict 'refs';
        *{$name} = subname $name => $code;
        return $code->();
    };
}

sub install {
    my ($self, $name ) = @_;
    $self->shadow($self->code_for($name));
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator;
    my $name = $self->strip_name;
    die unless $name;

    $self->inject_if_block('{ my $class = __PACKAGE__; no strict "refs"; *{"::$class"} = \{ setup => [], teardown => [] } }');
    $self->inject_if_block('use Test::Mini::Unit::Sugar::Advice (name => "teardown");');
    $self->inject_if_block('use Test::Mini::Unit::Sugar::Advice (name => "setup");');
    $self->inject_if_block('use Test::Mini::Unit::Sugar::Test;');
    $self->inject_if_block('use Test::Mini::Assertions;');
    $self->inject_if_block('use base "Test::Mini::TestCase";');
    $self->inject_if_block("package $name;");
    $self->inject_if_block($self->scope_injector_call());

    $self->install($name);
}

1;
