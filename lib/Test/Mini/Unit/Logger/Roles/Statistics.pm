use MooseX::Declare;

role Test::Mini::Unit::Logger::Roles::Statistics
{
  my %opts = ( traits => [ 'Number' ], is => 'rw', isa => 'Int', default => 0 );
  has 'assertion_count' => ( %opts, handles => { add_assertions => 'add' } );
  has 'test_count'      => ( %opts, handles => { incr_tested  => [ add => 1 ] } );
  has 'skip_count'      => ( %opts, handles => { incr_skipped => [ add => 1 ] } );
  has 'error_count'     => ( %opts, handles => { incr_errored => [ add => 1 ] } );
  has 'failure_count'   => ( %opts, handles => { incr_failed  => [ add => 1 ] } );

  after finish_test(@) { $self->incr_tested();       }
  after finish_test(@) { $self->add_assertions(pop); }
  after skip(@)        { $self->incr_skipped();      }
  after error(@)       { $self->incr_errored();      }
  after fail(@)        { $self->incr_failed();       }
}
