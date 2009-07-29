use MooseX::Declare;

class Mini::Unit::Syntax::Keyword::TestCase
{
  Moose::with __PACKAGE__, qw(
      MooseX::Declare::Syntax::MooseSetup
      MooseX::Declare::Syntax::RoleApplication
      MooseX::Declare::Syntax::Extending
  );

  around imported_moose_symbols { $orig->(@_), qw( extends has inner super ) }

  # method generate_export(@) { sub { $self->make_anon_metaclass } }

  around auto_make_immutable { 1 }

  # around make_anon_metaclass { Moose::Meta::Class->create_anon_class() }


  after add_optional_customizations($ctx, $package)
  {
    my $superclass = grep { /^extends/ } @{ $ctx->scope_code_parts() };
    $ctx->add_scope_code_parts("extends 'Mini::Unit::TestCase'") unless $superclass;
    $ctx->add_scope_code_parts("with 'Mini::Unit::Assertions'");
  }
}
