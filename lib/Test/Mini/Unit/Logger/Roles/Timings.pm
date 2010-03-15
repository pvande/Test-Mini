use MooseX::Declare;

role Test::Mini::Unit::Logger::Roles::Timings
{
  with qw/
    Test::Mini::Unit::Logger::Roles::Timings::TestSuite
    Test::Mini::Unit::Logger::Roles::Timings::TestCase
    Test::Mini::Unit::Logger::Roles::Timings::Test
  /;

  has 'start_times' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
      started_at => 'get',
    },
  );
  has 'end_times' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
      ended_at => 'get',
    },
  );

  method start(@keys)
  {
      $self->start_times->{join '#', @keys} = time();
  }

  method stop(@keys)
  {
      $self->end_times->{join '#', @keys} = time();
  }

  method time_for(@keys)
  {
    my $key = join '#', @keys;
    my $start = $self->started_at($key);
    my $end   = $self->ended_at($key) || time();
    return $end - $start;
  }
}
