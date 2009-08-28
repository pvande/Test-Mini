use MooseX::Declare;
use Moose::Autobox;

role MiniTest::Unit::Autobox::Container
{
  requires 'is_empty';
  requires 'contains';
}

Moose::Autobox->mixin_additional_role('ARRAY', role {
  with 'MiniTest::Unit::Autobox::Container';

  method is_empty($self:)          { $self->length == 0 }
  method contains($self: Any $obj) { $self->any() eq $obj }
}->name());

Moose::Autobox->mixin_additional_role('HASH', role {
  with 'MiniTest::Unit::Autobox::Container';

  method is_empty($self:)          { $self->keys->length == 0 }
  method contains($self: Any $obj) { [%$self]->contains($obj) }
}->name());

Moose::Autobox->mixin_additional_role('SCALAR', role {
  with 'MiniTest::Unit::Autobox::Container';

  method is_empty($self:)          { $self->length == 0 }
  method contains($self: Any $obj) { $self->index($obj) != -1 }
}->name());