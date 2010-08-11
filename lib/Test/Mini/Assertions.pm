use MooseX::Declare;

use Exception::Class 1.29
  'Test::Mini::Unit::Error', => {  },
  'Test::Mini::Unit::Assert' => { isa => 'Test::Mini::Unit::Error' },
  'Test::Mini::Unit::Skip'   => { isa => 'Test::Mini::Unit::Assert' },
;

role Test::Mini::Assertions is dirty
{
  use Scalar::Util 1.21 qw/ looks_like_number refaddr reftype /;
  use List::Util   1.21 qw/ min /;
  use List::MoreUtils   qw/ any /;

  requires 'run';

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

  sub deref {
    my ($ref) = @_;use Data::Dumper;
    return %$ref if reftype($ref) eq 'HASH';
    return @$ref if reftype($ref) eq 'ARRAY';
    return $$ref if reftype($ref) eq 'SCALAR';
    return $$ref if reftype($ref) eq 'REF';
    return refaddr($ref);
  }

  {
    use Data::Inspect;
    sub inspect {
      my $i = Data::Inspect->new();
      $i->inspect(@_);
    }
  }

  {
    use Sub::Install qw/ install_sub /;
    sub alias {
      install_sub { code => $_[0], as => $_[1] }
    }
  }

  {
    no warnings 'closure';
    our $assertion_count = 0;
    method count_assertions       { return $assertion_count }
    sub increment_assertion_count { $assertion_count += 1   }
    sub reset_assertion_count     { $assertion_count  = 0   }
  }

  after run(@) { reset_assertion_count(); }

  clean;

=item X<assert>(C<$test, $msg?>)
The C<assert> method takes a value to be tested for I<truthiness>, and an
optional method.

  assert 1;
  assert 'true', 'Truth should shine clear';
=cut
  method assert($class: Any $test, $msg = 'Assertion failed; no message given.')
  {
    increment_assertion_count();
    $msg = $msg->() if ref $msg eq 'CODE';

    Test::Mini::Unit::Assert->throw(
      message        => $msg,
      ignore_package => [__PACKAGE__, 'Moose::Exporter'],
    ) unless $test;

    return 1;
  }

=item X<refute>(C<$test, $msg?>)
The C<refute> method takes a value to be tested for I<truthiness>, and an
optional method.

    refute 0;
    refute undef, 'Deny the untruths';
=cut
  method refute($class: Any $test, $msg = 'Refutation failed; no message given.')
  {
      return __PACKAGE__->assert(!$test, $msg);
  }

=item X<assert_block>(C<$block, $msg?>)
The C<assert_block> method takes a coderef (C<$block>) and an optional message
(in arbitrary order), evaluates the coderef, and L<assert>s that the returned
value was I<truthy>.

  assert_block 'environmental insanity', sub { 1 + 1 == 3 };
  assert_block \&some_sub, 'expected better from &some_sub';
  assert_block sub { 'true' };
=cut
  method assert_block($class: $block, $msg?)
  {
    ($msg, $block) = ($block, $msg) if $msg && ref $block ne 'CODE';
    $msg = message('Expected block to return true value', $msg);
    __PACKAGE__->assert_instance_of($block, 'CODE');
    __PACKAGE__->assert($block->(), $msg);
  }

=item X<assert_can>(C<$obj, $method, $msg?>)
=item X<assert_responds_to>(C<$obj, $method, $msg?>)
C<assert_can> verifies that the given C<$obj> is capable of responding to the
given C<$method> name.  Aliased as C<assert_responds_to>.

  assert_can $date, 'day_of_week';
  assert_can $time, 'seconds', '$time cannot respond to #seconds';
=cut
  method assert_can($class: Any $obj, $method, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} (@{[ref $obj || 'SCALAR']}) to respond to #$method", $msg);
    __PACKAGE__->assert($obj->can($method), $msg);
  }
  alias assert_can => 'assert_responds_to';

=item X<assert_contains>(C<$collection, $obj, $msg?>)
=item X<assert_includes>(C<$collection, $obj, $msg?>)
C<assert_contains> will verify that the given C<$collection> contains the given
the given C<$obj> as a member.  Valid collections include I<ARRAY>s, I<HASH>es,
strings, and any object that reponds to the B<contains> method.  Aliased as
C<assert_includes>.

  assert_contains [qw/ 1 2 3 /], 2;
  assert_contains { a => 'b' }, 'a';  # 'b' also contained
  assert_contains 'expectorate', 'xp';
  assert_contains Collection->new(1, 2, 3), 2;  # if Collection->contains(2)
=cut
  method assert_contains($class: Any $collection, Any $obj, $m?)
  {
    my $msg = message("Expected @{[inspect($collection)]} to contain @{[inspect($obj)]}", $m);
    if (ref $collection eq 'ARRAY') {
      my $search = any {defined $obj ? $_ eq $obj : defined $_ } @$collection;
      __PACKAGE__->assert($search, $msg);
    }
    elsif (ref $collection eq 'HASH') {
      __PACKAGE__->assert_contains([%$collection], $obj, $m);
    }
    elsif (ref $collection) {
      __PACKAGE__->assert_can($collection, 'contains');
      __PACKAGE__->assert($collection->contains($obj), $msg);
    }
    else {
      __PACKAGE__->assert(index($collection, $obj) != -1, $msg);
    }
  }
  alias assert_contains => 'assert_includes';

=item X<assert_dies>(C<$sub, $error?, $msg?>)
C<assert_dies> succeeds if C<$sub> fails, and fails if C<$sub> succeeds.  If
C<$error> is provided, the error message from C<$@> must contain it.

  assert_dies sub { die 'LAGHLAGHLAGHL' };
  assert_dies sub { die 'Failure on line 27 in Foo.pm'}, 'line 27';
=cut
  method assert_dies($class: CodeRef $sub, $error='', $msg?)
  {
    $msg = message("Expected @{[inspect($sub)]} to die matching /$error/", $msg);
    my ($full_error, $dies);
    {
      local $@;
      $dies = not eval { $sub->(); return 1; };
      $full_error = $@;
    }
    $class->assert($dies, $msg);
    $class->assert_contains("$full_error", $error);
  }

=item X<assert_does>(C<$obj, $role, $msg?>)
C<assert_does> validates that the given C<$obj> does the given Moose Role
C<$role>.

  assert_does 'MyApp::Person', 'MyApp::Role::Mammal'  # if MyApp::Person->does('MyApp::Role::Mammal');
  assert_does $employee, 'MyApp::Role::Manager'  # if $employee->does('MyApp::Role::Manager');
=cut
  method assert_does($class: Any $obj, $role, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to perform the role of $role", $msg);
    __PACKAGE__->assert($obj->does($role), $msg);
  }

=item X<assert_empty>(C<$collection, $msg?>)
The C<assert_empty> method takes a C<$collection> and validates its emptiness.
Valid collections include I<ARRAY>s, I<HASH>es, strings, and any object that
reponds to B<is_empty>.

  assert_empty [];
  assert_empty {};
  assert_empty '';
  assert_empty Collection->new()  # if Collection->is_empty()
=cut
  method assert_empty($class: Any $collection, $msg?)
  {
    $msg = message("Expected @{[inspect($collection)]} to be empty", $msg);
    if (ref $collection eq 'ARRAY') {
      __PACKAGE__->refute(scalar @$collection, $msg);
    }
    elsif (ref $collection eq 'HASH') {
      __PACKAGE__->refute(scalar keys %$collection, $msg);
    }
    elsif (ref $collection) {
      __PACKAGE__->assert_can($collection, 'is_empty');
      __PACKAGE__->assert($collection->is_empty(), $msg);
    }
    else {
      __PACKAGE__->refute(length $collection, $msg);
    }
  }

=item X<assert_equal>(C<$actual, $expected, $msg?>)
=item X<assert_eq>(C<$actual, $expected, $msg?>)
C<assert_equal> checks two given objects for equality.  Aliased as C<assert_eq>.

This assertion, while not the most basic, ends up being one of the most
fundamental to most testing strategies.  Sadly, its nuance is not as unobtuse.

  assert_equal 3.000, 3;
  assert_equal lc('FOO'), 'foo';
  assert_equal [qw/ 1 2 3 /], [ 1, 2, 3 ];
  assert_equal { a => 'eh' }, { a => 'eh' };
  assert_equal Class->new(), $expected;  # if $expected->equals(Class->new())
=cut
  method assert_equal($class: Any $actual, Any $expected, $msg?)
  {
    $msg = message("Expected @{[inspect($expected)]}\n     not @{[inspect($actual)]}", $msg);

    my @expected = ($expected);
    my @actual   = ($actual);

    my $passed = 1;

    while ($passed && (@expected || @actual)) {
      ($expected, $actual) = (shift(@expected), shift(@actual));

      next if ref $expected && ref $actual &&
              refaddr($expected) == refaddr($actual);

      if (UNIVERSAL::can($expected, 'equals')) {
        $passed = $expected->equals($actual);
      }
      elsif (ref $expected eq 'ARRAY' && ref $actual eq 'ARRAY') {
        $passed = (@$expected == @$actual);
        unshift @expected, @$expected;
        unshift @actual, @$actual;
      }
      elsif (ref $expected eq 'HASH' && ref $actual eq 'HASH') {
        $passed = (keys %$expected == keys %$actual);
        unshift @expected, %$expected;
        unshift @actual, %$actual;
      }
      elsif (ref $expected && ref $actual) {
        $passed = (ref $expected eq ref $actual);
        unshift @expected, [ deref($expected) ];
        unshift @actual,   [ deref($actual)   ];
      }
      elsif (looks_like_number($expected) && looks_like_number($actual)) {
        $passed = ($expected == $actual);
      }
      elsif (defined $expected && defined $actual) {
        $passed = ($expected eq $actual);
      }
      else {
        $passed = !(defined $expected || defined $actual);
      }
    }

    __PACKAGE__->assert($passed, $msg);
  }
  alias assert_equal => 'assert_eq';

=item X<assert_kind_of>(C<$obj, $type, $msg?>)
The C<assert_kind_of> method validates that C<$obj> either I<isa> or I<does>
the given C<$type>.

  assert_kind_of List->new(), 'Collection',  # if List->isa('Collection')
  assert_kind_of List->new(), 'Enumerable'  # if List->does('Enumerable')
  assert_kind_of 'List', 'Collection',  # if List->isa('Collection')
  assert_kind_of 'List', 'Enumerable'  # if List->does('Enumerable')
=cut
  method assert_kind_of($class: Any $obj, $type, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to be a kind of $type", $msg);
    __PACKAGE__->assert($obj->isa($type) || $obj->does($type), $msg);
  }

=item X<assert_in_delta>(C<$actual, $expected, $delta = 0.001, $msg?>)
C<assert_in_delta> checks that the difference between C<$expected> and
C<$actual> is less than $delta (default 0.001).

  assert_in_delta 1.001, 1;
  assert_in_delta 104, 100, 5;
=cut
  method assert_in_delta($class: $actual, $expected, $delta = 0.001, $msg?)
  {
    my $n = abs($actual - $expected);
    $msg = message("Expected $actual - $expected ($n) to be < $delta", $msg);
    __PACKAGE__->assert($delta >= $n, $msg);
  }

=item X<assert_in_epsilon>(C<$a, $b, $epsilon = 0.001, $msg?>)
Like L<assert_in_delta>, but better at dealing with errors proportional to C<$a>
and C<$b>.

  assert_in_epsilon 220, 200, 0.10
  assert_in_epsilon 22.0 / 7.0, Math::Trig::pi;
=cut
  method assert_in_epsilon($class: $actual, $expected, $epsilon = 0.001, $msg?)
  {
    __PACKAGE__->assert_in_delta(
        $actual,
        $expected,
        min(abs($actual), abs($expected)) * $epsilon,
        $msg,
    );
  }

=item X<assert_instance_of>(C<$obj, $type, $msg?>)
C<assert_instance_of> validates that the given C<$obj> is an instance of
C<$type>.  For inheritance checks, see L<assert_isa>.

  assert_instance_of MyApp::Person->new(), 'MyApp::Person'
=cut
  method assert_instance_of($class: Any $obj, $type, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to be an instance of $type, not @{[ref $obj]}", $msg);
    __PACKAGE__->assert(ref $obj eq $type, $msg);
  }

=item X<assert_isa>(C<$obj, $type, $msg?>)
=item X<assert_is_a>(C<$obj, $type, $msg?>)
C<assert_isa> validates that C<$obj> inherits from C<$type>.  Aliased as
C<assert_is_a>.

  assert_isa 'MyApp::Employee', 'MyApp::Employee'
  assert_isa MyApp::Employee->new(), 'MyApp::Employee'
  assert_isa 'MyApp::Employee', 'MyApp::Person';  # if MyApp::Employee->isa('MyApp::Person')
  assert_isa MyApp::Employee->new(), 'MyApp::Person'  # if MyApp::Employee->isa('MyApp::Person')
=cut
  method assert_isa($class: Any $obj, $type, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to inherit from $type", $msg);
    __PACKAGE__->assert($obj->isa($type), $msg);
  }
  alias assert_isa => 'assert_is_a';

=item X<assert_match>(C<$pattern, $string, $msg?>)
C<assert_match> validates that the given C<$string> matches the given
C<$pattern>.

  assert_match qr/score/, 'Four score and seven years ago...'
=cut
  method assert_match($class: $string, $pattern, $msg?)
  {
    $msg = message("Expected qr/$pattern/ to match against @{[inspect($string)]}", $msg);
    __PACKAGE__->assert(scalar($string =~ $pattern), $msg);
  }

=item X<assert_undef>(C<$obj, $msg?>)
C<assert_undef> ensures that the given C<$obj> is undefined.

  assert_undef $value  # if not defined $value
=cut
  method assert_undef($class: Any $obj, $msg?)
  {
    $msg = message("Expected @{[inspect($obj)]} to be undef", $msg);
    __PACKAGE__->assert_equal($obj, undef, $msg);
  }

  method skip($class: $msg = 'Test skipped; no message given.')
  {
    $msg = $msg->() if ref $msg eq 'CODE';
    Test::Mini::Unit::Skip->throw(
      message        => $msg,
      ignore_package => [__PACKAGE__, 'Moose::Exporter'],
    );
  }

  method flunk($class: $msg = 'Epic failure')
  {
    __PACKAGE__->assert(0, $msg);
  }

  use Moose::Exporter;
  Moose::Exporter->setup_import_methods(
    with_caller => [
      grep { /^(assert|refute|skip$|flunk$)/ } __PACKAGE__->meta->get_method_list(),
    ],
  );
}
