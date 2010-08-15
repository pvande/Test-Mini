package Test::Mini::Unit;
use strict;
use warnings;
use 5.008;

use aliased 'Test::Mini::Unit::Sugar::TestCase',       'TestCaseKeyword';

sub import {
    my ($class, %args) = @_;
    my $caller = caller();

    strict->import;
    warnings->import;

    TestCaseKeyword->import(into => $caller);
}

use Test::Mini::Runner;

END {
    $| = 1;
    return if $?;
    $? = Test::Mini::Runner->new()->run();
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::Mini::Unit - Clean Unit Testing

=head1 SYNOPSIS

Real Documentation is coming.  In the meantime, enjoy the montage!

=head2 Traditional Style

  package TraditionalTest;

  use Test::Mini::Unit;
  use Test::Mini::Assertions;

  sub setup    { 'This runs before each test...' }
  sub teardown { 'This runs after each test...' }

  sub test_assert { assert 1, 'I should pass' }
  sub test_refute { refute 0, 'I should fail' }
  sub test_skip   { skip "I've got better things to do" }

  1;

=head2 Classical Style

  use Test::Mini::Unit;

  class ClassicalTest extends Test::Mini::Unit::TestCase
  {
    use Test::Mini::Assertions;

    method setup()    { 'This runs before each test...' }
    method teardown() { 'This runs after each test...' }

    method test_assert() { assert 1, 'I should pass' }
    method test_refute() { refute 0, 'I should fail' }
    method test_skip()   { skip "I've got better things to do" }
  }

=head2 Sweetened Style

  use Test::Mini::Unit;

  testcase SugaryTest
  {
    setup    { 'This runs before each test...' }
    teardown { 'This runs after each test...' }

    test passes() { assert 1, 'I should pass' }
    test refute() { refute 0, 'I should fail' }
    test skip()   { skip "I've got better things to do" }
  }

=head1 AUTHOR

Pieter Vande Bruggen, E<lt>pvande@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Pieter Vande Bruggen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
