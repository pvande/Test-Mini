use MooseX::Declare;

role MiniTest::Unit::Logger::Roles::Timings
{
  with qw/
    MiniTest::Unit::Logger::Roles::Timings::TestSuite
    MiniTest::Unit::Logger::Roles::Timings::TestCase
    MiniTest::Unit::Logger::Roles::Timings::Test
  /;

  use MooseX::AttributeHelpers;

  has 'start_times' => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    provides  => { get => 'started_at' },
    curries   => {
      set => {
        start => sub { $_[1]->($_[0], $_[2], time()) },
      },
    },
  );
  has 'end_times' => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    provides  => { get => 'ended_at' },
    curries   => {
      set => {
        stop => sub { $_[1]->($_[0], $_[2], time()) },
      },
    },
  );

  method time_for(@keys)
  {
    my $key = join '#', @keys;
    my $start = $self->started_at($key);
    my $end   = $self->ended_at($key) || time();
    return $end - $start;
  }
}