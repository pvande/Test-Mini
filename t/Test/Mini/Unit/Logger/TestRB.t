use Test::Mini::Unit;

class MyClass { }

testcase Test::Mini::Unit::Logger::TestRB::Test
{
  use aliased 'IO::Scalar' => 'Buffer';
  use aliased 'Test::Mini::Unit::Logger::TestRB' => 'Logger';

  use Text::Outdent 'outdent';

  my $buffer;
  has 'logger' => (
    is => 'rw',
    lazy => 1,
    default => sub {
      return Logger->new(buffer => Buffer->new(\($buffer = '')));
    },
  );

  test begin_test_suite_without_filter
  {
    $self->logger->begin_test_suite(seed => 'SEED');
    assert_equal outdent(<<"    TestRB"), $buffer
      Loaded Suite
      Seeded with SEED

    TestRB
  }

  test begin_test_suite_with_filter
  {
    $self->logger->begin_test_suite(seed => 'SEED', filter => 'FILTER');
    assert_equal outdent(<<"    TestRB"), $buffer
      Loaded Suite (Filtered to /FILTER/)
      Seeded with SEED

    TestRB
  }

  # TODO: Finish Tests
}
