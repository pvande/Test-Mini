use Test::Mini::Unit;

class ClassicTest extends Test::Mini::Unit::TestCase
{
  method setup()    { 'This runs before each test...' }
  method teardown() { 'This runs after each test...' }

  method test_assert() { $self->assert(1, 'I should pass') }
  method test_refute() { $self->refute(0, 'I should fail') }
  method test_skip()   { $self->skip("I've got better things to do") }

  use Test::Mini::Assertions;
  method test_imported_assert() { assert 1, 'I should pass' }
  method test_imported_refute() { refute 0, 'I should fail' }
  method test_imported_skip()   { skip "I've got better things to do" }
}