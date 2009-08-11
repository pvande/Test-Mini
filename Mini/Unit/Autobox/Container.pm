use MooseX::Declare;
use Moose::Autobox;

role Mini::Unit::Autobox::Container
{
  requires 'is_empty'
}

Moose::Autobox->mixin_additional_role('ARRAY', role {
  with 'Mini::Unit::Autobox::Container';

  method is_empty($self:) { $self->length == 0 }
}->name());

Moose::Autobox->mixin_additional_role('HASH', role {
  with 'Mini::Unit::Autobox::Container';

  method is_empty($self:) { $self->keys->length == 0 }
}->name());

Moose::Autobox->mixin_additional_role('SCALAR', role {
  with 'Mini::Unit::Autobox::Container';

  method is_empty($self:) { $self->length == 0 }
}->name());