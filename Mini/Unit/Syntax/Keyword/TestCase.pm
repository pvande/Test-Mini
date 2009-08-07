use MooseX::Declare;

class Mini::Unit::Syntax::Keyword::TestCase
{
  Moose::with __PACKAGE__, qw(
      MooseX::Declare::Syntax::MooseSetup
      MooseX::Declare::Syntax::RoleApplication
  );

  around imported_moose_symbols { $orig->(@_), qw( has inner super ) }

  after add_optional_customizations($ctx, $package)
  {
    $ctx->add_scope_code_parts("Moose::extends $package 'Mini::Unit::TestCase'");
    $ctx->add_scope_code_parts("use Mini::Unit::Assertions");
  }
}
