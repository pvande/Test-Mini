use MooseX::Declare;

role Mini::Unit::Syntax::Context::VerboseName
{
  method strip_verbose_name
  {
    my @name = qw( test );

    $self->skipspace;
    my $linestr = $self->get_linestr;

    my $name = substr($linestr, $self->offset, index($linestr, '{') - $self->offset);
    $name =~ s/^\s+|\s+$//g;

    $linestr = join(' ',
      substr($linestr, 0, $self->offset - 1),
      substr($linestr, index($linestr, '{'))
    );

    $self->set_linestr($linestr);

    return $name;
  }
}