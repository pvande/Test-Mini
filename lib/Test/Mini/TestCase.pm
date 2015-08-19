package Test::Mini::TestCase;

use 5.006;
use strict;
use warnings;

use Test::Mini;
use Exception::Class;
use Test::Mini::Assertions;

sub new {
    my ($class, %args) = @_;
    return bless { %args, passed => 0 }, $class;
}

sub setup {
    my ($self) = @_;
}

sub teardown {
    my ($self) = @_;
}

sub run {
    my ($self, $runner) = @_;
    my $e;
    my $test = $self->{name};

    eval {
        local $SIG{__DIE__} = sub {
            # Package declaration for isolating the callstack.
            # @api private
            package Test::Mini::SIGDIE;

            die $_[0] if eval {$_[0]->isa('Test::Mini::Exception')};

            (my $msg = "@_") =~ s/ at .*? line \d+\.\n$//;
            my $error = Test::Mini::Exception->new(
                message        => "$msg\n",
                ignore_package => [qw/ Test::Mini::SIGDIE Carp /],
            );

            my $me = $error->trace->frame(0);
            if ($me->{subroutine} eq 'Test::Mini::TestCase::__ANON__') {
                $me->{subroutine} = 'die';
                $me->{args} = [ $msg ];
            }

            die $error;
        };

        $self->setup();
        $self->$test();
        $self->{passed} = 1;

        die 'No assertions called' unless count_assertions();
    };

    if ($e = Exception::Class->caught()) {
        $self->{passed} = 0;

        if ($e = Exception::Class->caught('Test::Mini::Exception::Skip')) {
            $runner->skip(ref $self, $test, $e);
        }
        elsif ($e = Exception::Class->caught('Test::Mini::Exception::Assert')) {
            $runner->fail(ref $self, $test, $e);
        }
        elsif ($e = Exception::Class->caught('Test::Mini::Exception')) {
            $runner->error(ref $self, $test, $e);
        }
    }

    eval {
        $self->teardown();
        $runner->pass(ref $self, $self->{name}) if $self->{passed};
    };
    if ($e = Exception::Class->caught()) {
        $runner->error(ref $self, $test, $e);
    }

    return reset_assertions();
}

1;

__END__

=head1 NAME

Test::Mini::TestCase - base class for Test::Mini test cases

=head1 SYNOPSIS

 package TestSomething;
 use parent 'Test::Mini::TestCase';
 use Something;

 sub setup        { ... }
 sub test_can_foo { ... }
 sub teardown     { ... }

=head1 DESCRIPTION

This module should usually be the base class for any L<Test::Mini>
test cases that you write.

Any method whose name begins with C<test_> will be automatically run.
If you've defined a C<setup> method, that will be called before each test,
and if you've defined a C<teardown> method,
that will be called after each test.


=head1 CLASS METHODS

=head2 new(%args)

The one valid key you can pass is B<name>,
which gives the name of a specific test to run.


=head1 INSTANCE METHODS


=head2 setup()

Performs any initialisation required for the test,
run once before each test. Intended to be overridden
by subclasses.

   package TestSomething;
   use parent 'Test::Mini::TestCase';

   use Something;

   sub setup { $obj = Something->new(); }

   sub test_can_foo {
       assert_can($obj, 'foo');
   }


=head2 teardown()

Test teardown behavior, automatically invoked following each test.
Intended to be overridden by subclasses.

 package Test;
 use parent 'Test::Mini::TestCase';

 sub teardown { unlink 'foo.bar' }

 sub test_touching_files {
     `touch foo.bar`;
     assert(-f 'foo.bar');
 }


=head2 run($runner)

Runs the test specified at construction time.
This method is responsible for invoking the setup and teardown advice
for the method,
in addition to ensuring that any fatal errors encountered by the program
are suitably handled.
Appropriate diagnostic information should be sent to the supplied C<$runner>.

Returns the number of assertions called by this test.

Most of the time you won't need to override this method.


=head1 SEE ALSO

L<Test::Mini>

=head1 REPOSITORY

L<https://github.com/pvande/Test-Mini>

=head1 AUTHOR

Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by
Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

