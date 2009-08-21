use MooseX::Declare;

class Mini::Unit::Syntax::Keyword::Test extends MooseX::Declare::Syntax::Keyword::Method
{
  around parse($ctx)
  {
    $ctx->skip_declarator;
    local $Carp::Internal{'Devel::Declare'} = 1;

    my $name = $ctx->strip_name();
    return unless defined $name;

    my $method = MooseX::Method::Signatures::Meta::Method->wrap(
      signature    => qq{()},
      package_name => $ctx->get_curstash_name,
      name         => "test_$name",
    );

    $ctx->inject_if_block($ctx->scope_injector_call() . $method->injectable_code);

    $ctx->shadow(sub (&) {
      my $class = caller();
      $method->_set_actual_body(shift);
      return $self->register_method_declaration($class, $method);
    });
  }
}