package Test::Mini;

use strict;
use warnings;
use 5.006;

our $VERSION = '1.1.3_01';

sub runner_class { 'Test::Mini::Runner' }

END {
    $| = 1;
    return if $?;

    unless ($ENV{TEST_MINI_NO_AUTORUN}) {
        my $class = __PACKAGE__->runner_class;
        eval "require $class;";

        $? = $class->new()->run();
    }
}

1;

__END__

=head1 NAME

Test::Mini - lightweight xUnit testing for Perl

=head1 SYNOPSIS

 use parent 'Test::Mini::TestCase';

 sub setup    { ... }  # run before each test
 sub teardown { ... }  # run after each test

 sub test_something {
   ...
 }

=head1 DESCRIPTION

Test::Mini is a light, spry testing framework built to bring the familiarity
of an xUnit testing framework to Perl as a first-class citizen.
Based initially on Ryan Davis'
L<minitest|https://github.com/seattlerb/minitest>,
it provides a not only a simple way to
write and run tests, but the necessary infrastructure for more expressive
test fromeworks to be written.

Since example code speaks louder than words:

  package t::Test
  use parent 'Test::Mini::TestCase';
  use strict;
  use warnings;

  # This will run before each test
  sub setup { ... }

  # This will run after each test
  sub teardown { ... }

  sub test_something {
      my $self = shift;
      $self->assert(1); # Assertions come from Test::Mini::Assertions
  }

  # Assertions can also be imported...
  use Test::Mini::Assertions;

  sub helper { return 1 }

  sub test_something_else {
      assert(helper());
  }

Like any traditional xUnit framework, any method whose name begins with
'test' will be automatically run.  If you've declared 'setup' or 'teardown'
methods, they will be run before or after each test.

=head1 CLASS METHODS

=head2 runner_class

Returns the name of the test runner class to use.

=head1 SEE ALSO

L<https://github.com/seattlerb/minitest>

L<Test::Mini::Runner>

=head1 REPOSITORY

L<https://github.com/pvande/Test-Mini>

=head1 AUTHOR

Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

