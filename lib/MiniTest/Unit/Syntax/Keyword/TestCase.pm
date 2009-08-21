use MooseX::Declare;

class MiniTest::Unit::Syntax::Keyword::TestCase
{
  use aliased 'MiniTest::Unit::Syntax::Keyword::Test';
  use aliased 'MiniTest::Unit::Syntax::Keyword::Advice';

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
      Advice->new(identifier => 'setup'),
      Advice->new(identifier => 'teardown'),
    ]
  }

  after add_optional_customizations($ctx, $package)
  {
    $ctx->add_scope_code_parts("Moose::extends $package => 'MiniTest::Unit::TestCase'");
    $ctx->add_scope_code_parts("use MiniTest::Unit::Assertions");
  }
}
