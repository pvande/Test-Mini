use MooseX::Declare;

use Exception::Class
  'Mini::Unit::Error', => {  },
  'Mini::Unit::Assert' => { isa => 'Mini::Unit::Error' },
  'Mini::Unit::Skip'   => { isa => 'Mini::Unit::Assert' },
;

role Mini::Unit::Assertions
{
  use Moose::Autobox;
  use Mini::Unit::Autobox;
  no warnings 'closure';

  requires 'run';

  my $assertion_count = 0;
  method count_assertions { return $assertion_count }
  after run(@) { $assertion_count = 0; }

  sub message {
    my ($default, $msg) = @_;

    return sub {
      if ($msg) {
        $msg .= '.' if length($msg);
        $msg .= "\n$default.";
      }
      else {
        "$default."
      }
    }
  }

  method assert($class: Any $test, $msg = 'Assertion failed; no message given.')
  {
    $assertion_count += 1;
    $msg = $msg->() if ref $msg eq 'CODE';

    Mini::Unit::Assert->throw(
      message        => $msg,
      ignore_package => [__PACKAGE__, 'Moose::Exporter'],
    ) unless $test;

    return 1;
  }

  method assert_block($class: $msg_or_block, $block?)
  {
    my $msg = $msg_or_block if $block;
    $block ||= $msg_or_block;

    $msg = message('Expected block to return true value', $msg);
    $class->assert($block->(), $msg);
  }

  method assert_empty($class: $obj, $msg?)
  {
    $msg = message("Expected @{[$obj->dump]} to be empty", $msg);
    $class->assert_can($obj, 'is_empty');
    $class->assert($obj->is_empty(), $msg);
  }

  method assert_can($class: $obj, $method, $msg?)
  {
    $msg = message("Expected @{[$obj->dump]} (@{[ref $obj || 'SCALAR']}) to respond to #$method", $msg);
    $class->assert($obj->can($method), $msg);
  }

  method assert_contains($class: $collection, Any $obj, $msg?)
  {
    $msg = message("Expected @{[$collection->dump]} to contain @{[$obj->dump]}");
    $class->assert_can($collection, 'contains');
    $class->assert($collection->contains($obj), $msg);
  }

  method refute($class: $test, $msg = 'Refutation failed; no message given.')
  {
    return not $class->assert(!$test, $msg);
  }

  method skip($class: $msg = 'Test skipped; no message given.')
  {
    $msg = $msg->() if ref $msg eq 'CODE';
    Mini::Unit::Skip->throw(
      message        => $msg,
      ignore_package => [__PACKAGE__, 'Moose::Exporter'],
    );
  }

  method flunk($class: $msg = 'Epic failure')
  {
    $class->assert(0, $msg);
  }

  use Moose::Exporter;
  Moose::Exporter->setup_import_methods(
    with_caller => [
      grep { /^(assert|refute|skip$|flunk$)/ } __PACKAGE__->meta->get_method_list(),
    ],
  );
}