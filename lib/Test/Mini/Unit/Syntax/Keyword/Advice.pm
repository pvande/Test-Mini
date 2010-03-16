use MooseX::Declare;

class Test::Mini::Unit::Syntax::Keyword::Advice extends MooseX::Declare::Syntax::Keyword::MethodModifier
{
  around parse($ctx)
  {
    my $linestr = $ctx->get_linestr();  # <identifier> { ... }
    substr($linestr, $ctx->offset(), 0, $self->identifier . ' ');
    $ctx->set_linestr($linestr); # <identifier> <identifier> { ... }

    $self->$orig($ctx);
  }
}
