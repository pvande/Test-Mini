use MiniTest::Unit;

class MyClass { }

testcase MiniTest::Unit::Logger::TestRB::Test
{
  use IO::Scalar;
  use aliased 'MiniTest::Unit::Logger::TestRB' => 'TestRBLogger';

  has 'logger' => (is => 'rw');
  has 'buffer' => (is => 'rw');

  setup
  {
    $self->logger(
      TestRBLogger->new(
        buffer => my $buffer = IO::Scalar->new(),
      )
    );
    $self->buffer($buffer);
  }

  test begin_test_suite_without_filter
  {
    $self->logger->begin_test_suite(seed => 'SEED');
    assert_equal <<TestRB, "@{[$self->buffer]}"
Loaded Suite
Seeded with SEED

TestRB
  }

  test begin_test_suite_with_filter
  {
    $self->logger->begin_test_suite(seed => 'SEED', filter => 'FILTER');
    assert_equal <<TestRB, "@{[$self->buffer]}"
Loaded Suite (Filtered to /FILTER/)
Seeded with SEED

TestRB
  }

  # TODO: Finish Tests
}