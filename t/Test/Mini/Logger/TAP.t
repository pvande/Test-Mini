use Test::Mini::Unit;

class MyClass { }

testcase Test::Mini::Logger::TAP::Test
{
  use aliased 'IO::Scalar' => 'Buffer';
  use aliased 'Test::Mini::Logger::TAP' => 'Logger';

  use Text::Outdent 0.01 'outdent';

  my $buffer;
  has 'logger' => (
    is => 'rw',
    lazy => 1,
    default => sub {
      return Logger->new(buffer => Buffer->new(\($buffer = '')));
    },
  );

  test begin_test_case
  {
    $self->logger->begin_test_case('MyClass', qw/ method1 method2 method3 /);
    assert_equal outdent(<<'    TAP'), $buffer;
      1..3
      # Test Case: MyClass
    TAP
  }

  test pass
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->pass('MyClass', 'method1');
    assert_equal outdent(<<'    TAP'), $buffer;
      ok 1 - method1
    TAP
  }

  test two_passes
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->pass('MyClass', 'method1');

    $self->logger->begin_test('MyClass', 'method2');
    $self->logger->pass('MyClass', 'method2');

    assert_equal outdent(<<'    TAP'), $buffer;
      ok 1 - method1
      ok 2 - method2
    TAP
  }

  test fail
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->fail('MyClass', 'method1', 'Reason for failure');
    assert_equal outdent(<<'    TAP'), $buffer;
      not ok 1 - method1
      # Reason for failure
    TAP
  }

  test two_failures
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->fail('MyClass', 'method1', 'Daddy never loved me');

    $self->logger->begin_test('MyClass', 'method2');
    $self->logger->fail('MyClass', 'method2', 'Not enough hugs');

    assert_equal outdent(<<'    TAP'), $buffer;
      not ok 1 - method1
      # Daddy never loved me
      not ok 2 - method2
      # Not enough hugs
    TAP
  }

  test fail_with_multiline_reason
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->fail('MyClass', 'method1', "My Own Personal Failing:\nCaring too much");
    assert_equal outdent(<<'    TAP'), $buffer;
      not ok 1 - method1
      # My Own Personal Failing:
      # Caring too much
    TAP
  }

  test error
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->error('MyClass', 'method1', 'Reason for error');
    assert_equal outdent(<<'    TAP'), $buffer;
      not ok 1 - method1
      # Reason for error
    TAP
  }

  test two_errors
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->error('MyClass', 'method1', 'Off by one');

    $self->logger->begin_test('MyClass', 'method2');
    $self->logger->error('MyClass', 'method2', 'Suicide');

    assert_equal outdent(<<'    TAP'), $buffer;
      not ok 1 - method1
      # Off by one
      not ok 2 - method2
      # Suicide
    TAP
  }

  test error_with_multiline_reason
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->error('MyClass', 'method1', "Death,\nIt's final");
    assert_equal outdent(<<'    TAP'), $buffer;
      not ok 1 - method1
      # Death,
      # It's final
    TAP
  }

  test skip
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->skip('MyClass', 'method1', "School's boring");
    assert_equal outdent(<<'    TAP'), $buffer;
      ok 1 - method1 # SKIP: School's boring
    TAP
  }

  test two_skips
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->skip('MyClass', 'method1', 'One, two...');

    $self->logger->begin_test('MyClass', 'method2');
    $self->logger->skip('MyClass', 'method2', '... to my Lou');

    assert_equal outdent(<<'    TAP'), $buffer;
      ok 1 - method1 # SKIP: One, two...
      ok 2 - method2 # SKIP: ... to my Lou
    TAP
  }

  test skip_with_multiline_reason
  {
    $self->logger->begin_test('MyClass', 'method1');
    $self->logger->skip('MyClass', 'method1', "School's Cool\nDon't be a fool");
    assert_equal outdent(<<'    TAP'), $buffer;
      ok 1 - method1 # SKIP
      # School's Cool
      # Don't be a fool
    TAP
  }
}
