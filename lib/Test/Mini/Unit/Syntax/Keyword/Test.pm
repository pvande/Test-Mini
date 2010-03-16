use MooseX::Declare;

class Test::Mini::Unit::Syntax::Keyword::Test extends MooseX::Declare::Syntax::Keyword::Method
{
  around parse($ctx)
  {
    my $offset = $ctx->offset;

    $ctx->skip_declarator();
    $ctx->skipspace();

    my $linestr = $ctx->get_linestr(); # <identifier> foo_bar { ... }
    substr($linestr, $ctx->offset(), 0, 'test_');
    $ctx->set_linestr($linestr); # <identifier> test_foo_bar { ... }

    $ctx->_dd_context->{Offset} = $offset;

    $self->$orig($ctx);
  }
}
