use MooseX::Declare;

role MiniTest::Unit::Logger::Roles::Statistics
{
  use MooseX::AttributeHelpers;

  my %opts = ( metaclass => 'Number', is => 'rw', isa => 'Int', default => 0 );
  has 'assertion_count' => ( %opts, provides => { add => 'add_assertions' } );
  has 'test_count'      => ( %opts, curries => { add => { incr_tested  => [1] } } );
  has 'skip_count'      => ( %opts, curries => { add => { incr_skipped => [1] } } );
  has 'error_count'     => ( %opts, curries => { add => { incr_errored => [1] } } );
  has 'failure_count'   => ( %opts, curries => { add => { incr_failed  => [1] } } );

  after finish_test(@) { $self->incr_tested();       }
  after finish_test(@) { $self->add_assertions(pop); }
  after skip(@)        { $self->incr_skipped();      }
  after error(@)       { $self->incr_errored();      }
  after fail(@)        { $self->incr_failed();       }

  method statistics
  {
    # TODO: Handle statistics output formatting in the XUnit Logger
    join(', ',
      "@{[$self->test_count()]} tests",
      "@{[$self->assertion_count()]} assertions",
      "@{[$self->failure_count()]} failures",
      "@{[$self->error_count()]} errors",
      "@{[$self->skip_count()]} skips",
    );
  }
}