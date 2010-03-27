use MooseX::Declare;

use 5.008;

class Test::Mini::Unit
{
  our $VERSION = '0.5';

  use aliased 'MooseX::Declare::Syntax::Keyword::Class',     'ClassKeyword';
  use aliased 'MooseX::Declare::Syntax::Keyword::Role',      'RoleKeyword';
  use aliased 'Test::Mini::Unit::Syntax::Keyword::TestCase', 'TestCaseKeyword';

  method import(ClassName $class: %args)
  {
    my $caller = caller();

    strict->import;
    warnings->import;

    for my $keyword (
      ClassKeyword->new(identifier => 'class'),
      RoleKeyword->new(identifier => 'role'),
      TestCaseKeyword->new(identifier => 'testcase'),
    ) {
      $keyword->setup_for($caller, %args, provided_by => $class);
    }
  }

  use Test::Mini::Unit::Runner;

  END {
    $| = 1;
    return if $?;
    $? = Test::Mini::Unit::Runner->new_with_options()->run();
  }
}

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::Mini::Unit - Clean Unit Testing with Moose

=head1 SYNOPSIS

=head2 Traditional Style

  package TraditionalTest;

  use Test::Mini::Unit;
  use Test::Mini::Unit::Assertions;

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
    use Test::Mini::Unit::Assertions;

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

=head1 DESCRIPTION

Stub documentation for Test::Mini::Unit, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Pieter Vande Bruggen, E<lt>pvande@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Pieter Vande Bruggen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
