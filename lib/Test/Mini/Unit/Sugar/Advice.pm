package Test::Mini::Unit::Sugar::Advice;
use base 'Devel::Declare::MethodInstaller::Simple';
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless \%args, (ref $class || $class);
}

sub setup_for {
    my ($self, $package, %options) = @_;
    $self->install_methodhandler(
        into => $package,
        name => $self->{identifier},
        %options,
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);
    $self->skip_declarator();
    $self->inject_if_block($self->scope_injector_call());
    $self->install($self->{name});
}

sub code_for {
    my ($self, $modifier) = @_;
    my $class = $self->get_curstash_name();
    return sub (&) {
        no strict 'refs';
        push @{ $$class->{$modifier} }, shift;
    };
}

1;