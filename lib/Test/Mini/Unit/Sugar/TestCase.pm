use MooseX::Declare;

class Test::Mini::Unit::Sugar::TestCase
{
  use aliased 'Test::Mini::Unit::Sugar::Test';
  use aliased 'Test::Mini::Unit::Sugar::Advice';

  Moose::with __PACKAGE__, qw(
      MooseX::Declare::Syntax::MooseSetup
      MooseX::Declare::Syntax::RoleApplication
  );

  around imported_moose_symbols { $orig->(@_), qw( has inner ) }
  sub auto_make_immutable  { 1 }

  around default_inner
  {
    [
      @{$orig->()},
      Test->new(identifier => 'test'),
      Advice->new(identifier => 'setup',    modifier_type => 'after'),
      Advice->new(identifier => 'teardown', modifier_type => 'before'),
    ]
  }

  after add_optional_customizations($ctx, $package)
  {
    $ctx->add_scope_code_parts('__PACKAGE__->meta->superclasses("Test::Mini::Unit::TestCase")');
    $ctx->add_scope_code_parts('use Test::Mini::Assertions');
    $ctx->add_scope_code_parts('{ my $class = __PACKAGE__; no strict "refs"; $$class = { setup => [], teardown => [] } }');
  }
}
