use MooseX::Declare;

role MiniTest::Unit::Logger::Roles::Timings
{
  with qw/
    MiniTest::Unit::Logger::Roles::Timings::TestSuite
    MiniTest::Unit::Logger::Roles::Timings::TestCase
    MiniTest::Unit::Logger::Roles::Timings::Test
  /;

  has 'start_times' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
      started_at => 'get',
      start      => [
        set => sub { $_[1]->($_[0], $_[2], time()) },
      ],
    },
  );
  has 'end_times' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
      ended_at => 'get',
      stop     => [
        set => sub { $_[1]->($_[0], $_[2], time()) },
      ],
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
