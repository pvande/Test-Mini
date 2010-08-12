package Test::Mini::Unit::Sugar::Test;
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

    $self->skip_declarator;
    my $name   = $self->strip_name;
    my $inject = 'my $self = shift;';

    if (defined $name) {
        $inject = $self->scope_injector_call() . $inject;
    }
    else {
        $name = 0+$self;
    }

    $self->inject_if_block($inject);
    $self->install("test_$name");
}

1;
