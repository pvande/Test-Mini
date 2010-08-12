use Test::Mini::Unit;

class MyClass { }

testcase Test::Mini::Logger::Test
{
  use aliased 'IO::Scalar' => 'Buffer';
  use aliased 'Test::Mini::Logger' => 'Logger';

  my $buffer;
  has 'logger' => (
    is => 'rw',
    lazy => 1,
    default => sub {
      return Logger->new(buffer => Buffer->new(\($buffer = '')));
    },
  );

  test full_test_run_should_remain_silent
  {
    $self->logger->begin_test_suite();
    $self->logger->begin_test_case('MyClass', qw/ m1 m2 m3 m4 /);
    $self->logger->begin_test('MyClass', 'm1');
    $self->logger->pass('MyClass', 'm1');
    $self->logger->finish_test('MyClass', 'm1', 1);
    $self->logger->begin_test('MyClass', 'm2');
    $self->logger->fail('MyClass', 'm2', 'failure message');
    $self->logger->finish_test('MyClass', 'm2', 2);
    $self->logger->begin_test('MyClass', 'm3');
    $self->logger->error('MyClass', 'm3', 'error message');
    $self->logger->finish_test('MyClass', 'm3', 3);
    $self->logger->begin_test('MyClass', 'm4');
    $self->logger->skip('MyClass', 'm4', 'reason');
    $self->logger->finish_test('MyClass', 'm4', 0);
    $self->logger->finish_test_case('MyClass', qw/ m1 m2 m3 m4 /);
    $self->logger->finish_test_suite(1);

    assert_equal '', $buffer;
  }
}
