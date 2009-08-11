use MooseX::Declare;
use Moose::Autobox;

role Mini::Unit::Autobox::Container
{
  requires 'is_empty';
  requires 'contains';
}

Moose::Autobox->mixin_additional_role('ARRAY', role {
  with 'Mini::Unit::Autobox::Container';

  method is_empty($self:)          { $self->length == 0 }
  method contains($self: Any $obj) { $self->any() eq $obj }
}->name());

Moose::Autobox->mixin_additional_role('HASH', role {
  with 'Mini::Unit::Autobox::Container';

  method is_empty($self:)          { $self->keys->length == 0 }
  method contains($self: Any $obj) { $self->keys->contains($obj) }
}->name());

Moose::Autobox->mixin_additional_role('SCALAR', role {
  with 'Mini::Unit::Autobox::Container';

  method is_empty($self:)          { $self->length == 0 }
  method contains($self: Any $obj) { $self->index($obj) != -1 }
}->name());