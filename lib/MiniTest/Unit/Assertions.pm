use MooseX::Declare;

use Exception::Class
  'Mini::Unit::Error', => {  },
  'Mini::Unit::Assert' => { isa => 'Mini::Unit::Error' },
  'Mini::Unit::Skip'   => { isa => 'Mini::Unit::Assert' },
;

role Mini::Unit::Assertions is dirty
{
  use Moose::Autobox;
  use Mini::Unit::Autobox;
  use Data::Inspect ();
  use Data::Dumper;
  use List::Util qw/ min /;
  use Sub::Install qw/ install_sub /;
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

  sub inspect {
    my $i = Data::Inspect->new();
    $i->set_option('truncate_strings', 16);
    $i->inspect(@_);
  }

  sub alias {
    install_sub { code => $_[0], as => $_[1] }
  }

  clean;

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
    $class->assert_instance_of($block, 'CODE');
    $class->assert($block->(), $msg);
  }

  method assert_empty($class: Any $obj, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to be empty", $msg);
    $class->assert_can($obj, 'is_empty');
    $class->assert($obj->is_empty(), $msg);
  }

  method assert_equal($class: Any $expected, Any $actual, $msg?)
  {
    $msg = message("Expected @{[inspect($expected)]}, not @{[inspect($actual)]}", $msg);
    if ($expected->can('equals')) {
      $class->assert($expected->equals($actual), $msg);
    }
    elsif ((defined $expected && defined $actual) && ((not ref $expected) && (not ref $actual))) {
      $class->assert($expected eq $actual, $msg);
    }
    else {
      $class->assert(Dumper($expected) eq Dumper($actual), $msg);
    }
  }
  alias assert_equal => 'assert_eq';

  method assert_in_delta($class: $expected, $actual, $delta, $msg?)
  {
    my $n = abs($expected - $actual);
    $msg = message("Expected $expected - $actual ($n) to be < $delta", $msg);
    $class->assert($delta >= $n, $msg);
  }

  method assert_in_epsilon($class: $a, $b, $epsilon, $msg?)
  {
    $class->assert_in_delta($a, $b, min($a, $b) * $epsilon, $msg);
  }

  method assert_can($class: Any $obj, $method, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} (@{[ref $obj || 'SCALAR']}) to respond to #$method", $msg);
    $class->assert($obj->can($method), $msg);
  }
  alias assert_can => 'assert_respond_to';

  method assert_contains($class: Any $collection, Any $obj, $msg?)
  {
    $msg = message("Expected @{[inspect($collection)]} to contain @{[inspect($obj)]}", $msg);
    $class->assert_can($collection, 'contains');
    $class->assert($collection->contains($obj), $msg);
  }
  alias assert_contains => 'assert_includes';

  method assert_instance_of($class: Any $obj, $type, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to be an instance of $type, not @{[ref $obj]}", $msg);
    $class->assert(ref $obj eq $type, $msg);
  }

  method assert_isa($class: Any $obj, $type, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to inherit from $type", $msg);
    $class->assert($obj->isa($type), $msg);
  }
  alias assert_isa => 'assert_is_a';

  method assert_does($class: Any $obj, $role, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to perform the role of $role", $msg);
    $class->assert($obj->does($role), $msg);
  }

  method assert_kind_of($class: Any $obj, $type, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to be a kind of $type", $msg);
    $class->assert($obj->isa($type) || $obj->does($type), $msg);
  }

  method assert_match($class: $pattern, $string, $msg?)
  {
    $msg = message("Expected qr/$pattern/ to match against @{[inspect($string)]}", $msg);
    $class->assert(scalar($string =~ $pattern), $msg);
  }

  method assert_undef($class: Any $obj, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to be undef", $msg);
    $class->assert_equal($obj, undef, $msg);
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