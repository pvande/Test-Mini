use MooseX::Declare;

role Mini::Unit::Logger::Roles::Statistics
{
  use MooseX::AttributeHelpers;

  my %opts = ( metaclass => 'Number', is => 'rw', isa => 'Int', default => 0 );
  has 'assertions' => ( %opts, provides => { add => 'add_assertions' } );
  has 'tests'      => ( %opts, curries => { add => { incr_tested  => [1] } } );
  has 'skips'      => ( %opts, curries => { add => { incr_skipped => [1] } } );
  has 'errors'     => ( %opts, curries => { add => { incr_errored => [1] } } );
  has 'failures'   => ( %opts, curries => { add => { incr_failed  => [1] } } );

  after finish_test(@) { $self->incr_tested();       }
  after finish_test(@) { $self->add_assertions(pop); }
  after skip(@)        { $self->incr_skipped();      }
  after error(@)       { $self->incr_errored();      }
  after fail(@)        { $self->incr_failed();       }

  method statistics
  {
    join(', ',
      "@{[$self->tests()]} tests",
      "@{[$self->assertions()]} assertions",
      "@{[$self->failures()]} failures",
      "@{[$self->errors()]} errors",
      "@{[$self->skips()]} skips",
    );
  }
}