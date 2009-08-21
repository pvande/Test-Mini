use MooseX::Declare;

class MiniTest::Unit::Syntax::Keyword::Advice extends MooseX::Declare::Syntax::Keyword::Method
{
  around parse($ctx)
  {
    local $Carp::Internal{'Devel::Declare'} = 1;

    my $method = MooseX::Method::Signatures::Meta::Method->wrap(
      signature    => qq{()},
      package_name => $ctx->get_curstash_name,
      name         => $self->identifier,
    );

    $ctx->skip_declarator();
    $ctx->inject_if_block($ctx->scope_injector_call() . $method->injectable_code);

    $ctx->shadow(sub (&) {
      my $class = caller();
      $method->_set_actual_body(shift);
      return $self->register_method_declaration($class, $method);
    });
  }

  sub register_method_declaration {
      my ($self, $class, $method) = @_;
      unless ($class->can($method->name)) {
        return $class->meta->add_method($method->name, $method);
      }
      else {
        return Moose::Util::add_method_modifier($class, 'after', [$method->name, $method->body]);
      }
  }
}