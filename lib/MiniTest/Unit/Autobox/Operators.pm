use MooseX::Declare;
use Moose::Autobox;

role MiniTest::Unit::Autobox::Operators {}

Moose::Autobox->mixin_additional_role('ARRAY', role {
  with 'MiniTest::Unit::Autobox::Operators';

  method equals($self: Any $test)
  {
    return 0 unless ref $self eq ref $test;
    return 0 unless @$self eq @$test;

    foreach my $i (0..$#$self) {
      return 0 unless $self->[$i]->can('equals')
        ? $self->[$i]->equals($test->[$i])
        : $self->[$i] eq $test->[$i];
    }

    return 1;
  }
}->name());

Moose::Autobox->mixin_additional_role('SCALAR', role {
  with 'MiniTest::Unit::Autobox::Operators';

  use Scalar::Util qw/ looks_like_number /;
  method equals($self: $test)
  {
    if (looks_like_number($self) && looks_like_number($test)) {
      return $self == $test;
    }
    else {
      return $self eq $test;
    }
  }
}->name());