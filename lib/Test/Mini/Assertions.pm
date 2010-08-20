# A simple base class for exceptions raised during test runs.
package Test::Mini::Exception;
use base 'Exception::Class::Base';

# An exception that is raised when an assertion fails.
package Test::Mini::Exception::Assert;
use base 'Test::Mini::Exception';

# An exception that is raised to indicate that the remainder of the test
# should be skipped.
package Test::Mini::Exception::Skip;
use base 'Test::Mini::Exception::Assert';

# The basic set of assertions for use with the {Test::Mini} framework.
package Test::Mini::Assertions;
use strict;
use warnings;

use Scalar::Util 1.21 qw/ looks_like_number refaddr reftype /;
use List::Util   1.21 qw/ min /;
use List::MoreUtils   qw/ any /;
use Sub::Install      qw/ install_sub /;
use Data::Inspect;

# Formats error messages, appending periods and defaulting undefs as
# appropriate.
#
# @param $default [String] The default message to use.
# @param $msg [String] (undef) A message to use in place of the default.
# @return A well-formatted message.
# @private
sub message {
    my ($default, $msg) = @_;

    $msg .= $msg ? ".\n" : '';
    $msg .= "$default.";

    return sub { return $msg };
}

# Dereferences the given argument, if possible.
#
# @param $ref The argument to dereference.
# @return The referenced value or values.
# @private
sub deref {
    my ($ref) = @_;
    return %$ref if reftype($ref) eq 'HASH';
    return @$ref if reftype($ref) eq 'ARRAY';
    return $$ref if reftype($ref) eq 'SCALAR';
    return $$ref if reftype($ref) eq 'REF';
    return refaddr($ref);
}

# Produce a more useful string representation of the given argument.
#
# @param $obj The object to describe.
# @return [String] A description of the given object.
# @private
sub inspect {
    Data::Inspect->new()->inspect(@_);
}

my $assertion_count = 0;

use namespace::clean;

# Pulls all of the test-related methods into the calling package.
sub import {
    my ($class) = @_;
    my $caller = caller;

    no strict 'refs';
    *{"$caller\::count_assertions"} = \&_count_assertions;
    *{"$caller\::reset_assertions"} = \&_reset_assertions;

    my @asserts = grep { /^(assert|refute|skip$|flunk$)/ && defined &{$_} } keys %{"$class\::"};

    for my $assertion (@asserts) {
        *{"$caller\::$assertion"} = \&{$assertion};
    }
}

sub _count_assertions { return $assertion_count }
sub _reset_assertions { $assertion_count  = 0   }


# Asserts that +$test+ is truthy, and throws a {Test::Mini::Exception::Assert}
# if that assertion fails.
#
# @example
#   assert 1;
# @example
#   assert 'true', 'Truth should shine clear';
#
# @param $test The value to test.
# @param [String] $msg (undef) An optional description.
sub assert ($;$) {
    my ($test, $msg) = @_;
    $msg ||= 'Assertion failed; no message given.';
    $msg = $msg->() if ref $msg eq 'CODE';

    $assertion_count++;

    return 1 if $test;

    Test::Mini::Exception::Assert->throw(
        message        => $msg,
        ignore_package => [__PACKAGE__],
    );
}

# Asserts that +$test+ is falsey, and throws a {Test::Mini::Exception::Assert}
# if that assertion fails.
#
# @example
#   refute 0;
# @example
#   refute undef, 'Deny the untruths';
#
# @param $test The value to test.
# @param [String] $msg (undef) An optional description.
sub refute ($;$) {
    my ($test, $msg) = @_;
    $msg ||= 'Refutation failed; no message given.';
    return assert(!$test, $msg);
}

# Asserts that the given code reference returns a truthy value.
#
# @example
#   assert_block { 'true' };
# @example
#   assert_block \&some_sub, 'expected better from &some_sub';
#
# @param [CODE] $block The coderef to test.
# @param [String] $msg (undef) An optional description.
sub assert_block (&;$) {
    my ($block, $msg) = @_;
    ($msg, $block) = ($block, $msg) if $msg && ref $block ne 'CODE';
    $msg = message('Expected block to return true value', $msg);
    assert_instance_of($block, 'CODE');
    assert($block->(), $msg);
}

# Asserts that the given code reference returns a falsey value.
#
# @example
#   refute_block { '' };
# @example
#   refute_block \&some_sub, 'expected worse from &some_sub';
#
# @param [CODE] $block The coderef to test.
# @param [String] $msg (undef) An optional description.
sub refute_block (&;$) {
    my ($block, $msg) = @_;
    ($msg, $block) = ($block, $msg) if $msg && ref $block ne 'CODE';
    $msg = message('Expected block to return false value', $msg);
    assert_instance_of($block, 'CODE');
    refute($block->(), $msg);
}

# Verifies that the given +$obj+ is capable of responding to the given
# +$method+ name.  Also available as {#assert_responds_to}.
#
# @example
#   assert_can $date, 'day_of_week';
# @example
#   assert_can $time, 'seconds', '$time cannot respond to #seconds';
#
# @param $obj The object being tested.
# @param [String] $method The method name being checked for.
# @param [String] $msg (undef) An optional description.
sub assert_can ($$;$) {
    my ($obj, $method, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} (@{[ref $obj || 'SCALAR']}) to respond to #$method", $msg);
    assert($obj->can($method), $msg);
}

# Verifies that the given +$obj+ is *not* capable of responding to the given
# +$method+ name.  Also available as {#refute_responds_to}.
#
# @example
#   refute_can $date, 'to_time';
# @example
#   refute_can $time, 'day', '$time cannot respond to #day';
#
# @param $obj The object being tested.
# @param [String] $method The method name being checked.
# @param [String] $msg (undef) An optional description.
sub refute_can ($$;$) {
    my ($obj, $method, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} (@{[ref $obj || 'SCALAR']}) to not respond to #$method", $msg);
    refute($obj->can($method), $msg);
}

# Verifies that the given +$collection+ contains the given +$obj+ as a member.
# Aliased as {#assert_includes}.
#
# @example
#   assert_contains [qw/ 1 2 3 /], 2;
# @example
#   assert_contains { a => 'b' }, 'a';  # 'b' also contained
# @example
#   assert_contains 'expectorate', 'xp';
# @example
#   assert_contains Collection->new(1, 2, 3), 2;  # if Collection->contains(2)
#
# @param [Array|Hash|String|#contains] $collection The collection to test.
# @param $obj The needle to find.
# @param [String] $msg (undef) An optional description.
sub assert_contains ($$;$) {
    my ($collection, $obj, $msg) = @_;
    my $m = message("Expected @{[inspect($collection)]} to contain @{[inspect($obj)]}", $msg);
    if (ref $collection eq 'ARRAY') {
        my $search = any {defined $obj ? $_ eq $obj : defined $_ } @$collection;
        assert($search, $m);
    }
    elsif (ref $collection eq 'HASH') {
        &assert_contains([%$collection], $obj, $msg);
    }
    elsif (ref $collection) {
        assert_can($collection, 'contains');
        assert($collection->contains($obj), $m);
    }
    else {
        assert(index($collection, $obj) != -1, $m);
    }
}

# Verifies that the given +$collection+ does not contain the given +$obj+ as a
# member.  Aliased as {#refute_includes}.
#
# @example
#   refute_contains [qw/ 1 2 3 /], 5;
# @example
#   refute_contains { a => 'b' }, 'x';
# @example
#   refute_contains 'expectorate', 'spec';
# @example
#   refute_contains Collection->new(1, 2, 3), 5;  # unless Collection->contains(5)
#
# @param [Array|Hash|String|#contains] $collection The collection to test.
# @param $obj The needle to look for.
# @param [String] $msg (undef) An optional description.
sub refute_contains ($$;$) {
    my ($collection, $obj, $msg) = @_;
    my $m = message("Expected @{[inspect($collection)]} to not contain @{[inspect($obj)]}", $msg);
    if (ref $collection eq 'ARRAY') {
        my $search = any {defined $obj ? $_ eq $obj : defined $_ } @$collection;
        refute($search, $m);
    }
    elsif (ref $collection eq 'HASH') {
        &refute_contains([%$collection], $obj, $msg);
    }
    elsif (ref $collection) {
        assert_can($collection, 'contains');
        refute($collection->contains($obj), $m);
    }
    else {
        refute(index($collection, $obj) != -1, $m);
    }
}

# Validates that the given +$obj+ is defined.
# @see #refute_undef
sub assert_defined ($;$) { goto &refute_undef }

# Validates that the given +$obj+ is undefined.
# @see #assert_undef
sub refute_defined ($;$) { goto &assert_undef }

# Tests that the supplied code block dies, and fails if it succeeds.  If
# +$error+ is provided, the error message in +$@+ must contain it.
#
# @example
#   assert_dies { die 'LAGHLAGHLAGHL' };
# @example
#   assert_dies { die 'Failure on line 27 in Foo.pm' } 'line 27';
#
# @param [CODE] $sub The code that should die.
# @param [String] $error ('') The error substring expected.
# @param [String] $msg (undef) An optional description.
sub assert_dies (&;$$) {
    my ($sub, $error, $msg) = @_;
    $error = '' unless defined $error;

    $msg = message("Expected @{[inspect($sub)]} to die matching /$error/", $msg);
    my ($full_error, $dies);
    {
        local $@;
        $dies = not eval { $sub->(); return 1; };
        $full_error = $@;
    }
    assert($dies, $msg);
    assert_contains("$full_error", $error);
}

# Verifies the emptiness of a collection.
#
# @example
#   assert_empty [];
# @example
#   assert_empty {};
# @example
#   assert_empty '';
# @example
#   assert_empty Collection->new();  # if Collection->new()->is_empty()
#
# @param [Array|Hash|String|#is_empty] $collection The collection under scrutiny.
# @param [String] $msg (undef) An optional description.
sub assert_empty ($;$) {
    my ($collection, $msg) = @_;
    $msg = message("Expected @{[inspect($collection)]} to be empty", $msg);
    if (ref $collection eq 'ARRAY') {
        refute(@$collection, $msg);
    }
    elsif (ref $collection eq 'HASH') {
        refute(keys %$collection, $msg);
    }
    elsif (ref $collection) {
        assert_can($collection, 'is_empty');
        assert($collection->is_empty(), $msg);
    }
    else {
        refute(length $collection, $msg);
    }
}

# Verifies the non-emptiness of a collection.
#
# @example
#   refute_empty [ 1 ];
# @example
#   refute_empty { a => 1 };
# @example
#   refute_empty 'full';
# @example
#   refute_empty Collection->new();  # unless Collection->new()->is_empty()
#
# @param [Array|Hash|String|#is_empty] $collection The collection under scrutiny.
# @param [String] $msg (undef) An optional description.
sub refute_empty ($;$) {
    my ($collection, $msg) = @_;
    $msg = message("Expected @{[inspect($collection)]} to not be empty", $msg);
    if (ref $collection eq 'ARRAY') {
        assert(@$collection, $msg);
    }
    elsif (ref $collection eq 'HASH') {
        assert(keys %$collection, $msg);
    }
    elsif (ref $collection) {
        assert_can($collection, 'is_empty');
        refute($collection->is_empty(), $msg);
    }
    else {
        assert(length $collection, $msg);
    }
}

# Checks two given arguments for equality.
# @see #assert_equal
sub assert_eq { goto &assert_equal }

# Checks two given arguments for inequality.
# @see #assert_equal
sub refute_eq { goto &refute_equal }

# Checks two given arguments for equality.  Aliased as {#assert_eq}.
#
# @example
#   assert_equal 3.000, 3;
# @example
#   assert_equal lc('FOO'), 'foo';
# @example
#   assert_equal [qw/ 1 2 3 /], [ 1, 2, 3 ];
# @example
#   assert_equal { a => 'eh' }, { a => 'eh' };
# @example
#   assert_equal Class->new(), $expected;  # if $expected->equals(Class->new())
#
# @param $actual The value under test.
# @param $expected The expected value.
# @param [String] $msg (undef) An optional description.
sub assert_equal ($$;$) {
    my ($actual, $expected, $msg) = @_;
    $msg = message("Got @{[inspect($actual)]}\nnot @{[inspect($expected)]}", $msg);

    my @expected = ($expected);
    my @actual   = ($actual);

    my $passed = 1;

    while ($passed && (@actual || @expected)) {
        ($actual, $expected) = (shift(@actual), shift(@expected));

        next if ref $actual && ref $expected && refaddr($actual) == refaddr($expected);

        if (UNIVERSAL::can($expected, 'equals')) {
            $passed = $expected->equals($actual);
        }
        elsif (ref $actual eq 'ARRAY' && ref $expected eq 'ARRAY') {
            $passed = (@$actual == @$expected);
            unshift @actual, @$actual;
            unshift @expected, @$expected;
        }
        elsif (ref $actual eq 'HASH' && ref $expected eq 'HASH') {
            $passed = (keys %$actual == keys %$expected);
            unshift @actual, %$actual;
            unshift @expected, %$expected;
        }
        elsif (ref $actual && ref $expected) {
            $passed = (ref $actual eq ref $expected);
            unshift @actual,   [ deref($actual)   ];
            unshift @expected, [ deref($expected) ];
        }
        elsif (looks_like_number($actual) && looks_like_number($expected)) {
            $passed = ($actual == $expected);
        }
        elsif (defined $actual && defined $expected) {
            $passed = ($actual eq $expected);
        }
        else {
            $passed = !(defined $actual || defined $expected);
        }
    }

    assert($passed, $msg);
}

# Checks two given arguments for inequality.  Aliased as {#refute_eq}.
#
# @example
#   refute_equal 3.001, 3;
# @example
#   refute_equal lc('FOOL'), 'foo';
# @example
#   refute_equal [qw/ 1 23 /], [ 1, 2, 3 ];
# @example
#   refute_equal { a => 'ae' }, { a => 'eh' };
# @example
#   refute_equal Class->new(), $expected;  # unless $expected->equals(Class->new())
#
# @param $actual The value under test.
# @param $expected The tested value.
# @param [String] $msg (undef) An optional description.
sub refute_equal ($$;$) {
    my ($actual, $unexpected, $msg) = @_;
    $msg = message("The given values were unexpectedly equal", $msg);

    my @unexpected = ($unexpected);
    my @actual   = ($actual);

    my $passed = 1;

    while ($passed && (@actual || @unexpected)) {
        ($actual, $unexpected) = (shift(@actual), shift(@unexpected));

        next if ref $actual && ref $unexpected && refaddr($actual) == refaddr($unexpected);

        if (UNIVERSAL::can($unexpected, 'equals')) {
            $passed = $unexpected->equals($actual);
        }
        elsif (ref $actual eq 'ARRAY' && ref $unexpected eq 'ARRAY') {
            $passed = (@$actual == @$unexpected);
            unshift @actual, @$actual;
            unshift @unexpected, @$unexpected;
        }
        elsif (ref $actual eq 'HASH' && ref $unexpected eq 'HASH') {
            $passed = (keys %$actual == keys %$unexpected);
            unshift @actual, %$actual;
            unshift @unexpected, %$unexpected;
        }
        elsif (ref $actual && ref $unexpected) {
            $passed = (ref $actual eq ref $unexpected);
            unshift @actual,     [ deref($actual)   ];
            unshift @unexpected, [ deref($unexpected) ];
        }
        elsif (looks_like_number($actual) && looks_like_number($unexpected)) {
            $passed = ($actual == $unexpected);
        }
        elsif (defined $actual && defined $unexpected) {
            $passed = ($actual eq $unexpected);
        }
        else {
            $passed = !(defined $actual || defined $unexpected);
        }
    }

    refute($passed, $msg);
}

# Checks that the difference between +$actual+ and +$expected+ is less than
# +$delta+.
#
# @example
#   assert_in_delta 1.001, 1;
# @example
#   assert_in_delta 104, 100, 5;
#
# @param [Number] $actual The tested value.
# @param [Number] $expected The static value.
# @param [Number] $delta (0.001) The expected delta.
# @param [String] $msg (undef) An optional description.
sub assert_in_delta ($$;$$) {
    my ($actual, $expected, $delta, $msg) = @_;
    $delta = 0.001 unless defined $delta;
    my $n = abs($actual - $expected);
    $msg = message("Expected $actual - $expected ($n) to be < $delta", $msg);
    assert($delta >= $n, $msg);
}

# Checks that the difference between +$actual+ and +$expected+ is greater than
# +$delta+.
#
# @example
#   refute_in_delta 1.002, 1;
# @example
#   refute_in_delta 106, 100, 5;
#
# @param [Number] $actual The tested value.
# @param [Number] $expected The static value.
# @param [Number] $delta (0.001) The delta +$actual+ and +$expected+ are
#        expected to differ by.
# @param [String] $msg (undef) An optional description.
sub refute_in_delta ($$;$$) {
    my ($actual, $expected, $delta, $msg) = @_;
    $delta = 0.001 unless defined $delta;
    my $n = abs($actual - $expected);
    $msg = message("Expected $actual - $expected ($n) to be > $delta", $msg);
    refute($delta >= $n, $msg);
}

# Like {#assert_in_delta}, but better at dealing with errors proportional to
# the given arguments.
#
# @example
#   assert_in_epsilon 22.0 / 7.0, Math::Trig::pi;
# @example
#   assert_in_epsilon 220, 200, 0.10
#
# @param [Number] $actual The tested value.
# @param [Number] $expected The static value.
# @param [Number] $epsilon (0.001) The expected tolerance factor.
# @param [String] $msg (undef) An optional description.
sub assert_in_epsilon ($$;$$) {
    my ($actual, $expected, $epsilon, $msg) = @_;
    $epsilon = 0.001 unless defined $epsilon;
    assert_in_delta(
        $actual,
        $expected,
        min(abs($actual), abs($expected)) * $epsilon,
        $msg,
    );
}

# Like {#refute_in_delta}, but better at dealing with errors proportional to
# the given arguments.
#
# @example
#   refute_in_epsilon 21.0 / 7.0, Math::Trig::pi;
# @example
#   refute_in_epsilon 220, 200, 0.20
#
# @param [Number] $actual The tested value.
# @param [Number] $expected The static value.
# @param [Number] $epsilon (0.001) The factor by which +$actual+ and
#        +$expected+ are expected to differ by.
# @param [String] $msg (undef) An optional description.
sub refute_in_epsilon ($$;$$) {
    my ($actual, $expected, $epsilon, $msg) = @_;
    $epsilon = 0.001 unless defined $epsilon;
    refute_in_delta(
        $actual,
        $expected,
        min(abs($actual), abs($expected)) * $epsilon,
        $msg,
    );
}

# Verifies that the given +$collection+ contains the given +$obj+ as a member.
# @see #assert_contains
sub assert_includes ($$;$) { goto &assert_contains }

# Verifies that the given +$collection+ does not contain the given +$obj+ as a
# member.
# @see #refute_includes
sub refute_includes ($$;$) { goto &refute_contains }

# Validates that the given object is an instance of +$type+.
#
# @example
#   assert_instance_of MyApp::Person->new(), 'MyApp::Person';
#
# @param $obj The instance to check.
# @param [Class] $type The type to expect.
# @param [String] $msg (undef) An optional description.
# @see #assert_is_a
sub assert_instance_of ($$;$) {
    my ($obj, $type, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} to be an instance of $type, not @{[ref $obj]}", $msg);
    assert(ref $obj eq $type, $msg);
}

# Validates that +$obj+ inherits from +$type+.  Aliased as {#assert_isa}.
#
# @example
#   assert_is_a 'Employee', 'Employee';
# @example
#   assert_is_a Employee->new(), 'Employee';
# @example
#   assert_is_a 'Employee', 'Person'; # assuming Employee->isa('Person')
# @example
#   assert_is_a Employee->new(), 'Person';
#
# @param $obj The instance or class to check.
# @param [Class] $type The expected superclass.
# @param [String] $msg (undef) An optional description.
sub assert_is_a($$;$) {
    my ($obj, $type, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} to inherit from $type", $msg);
    assert($obj->isa($type), $msg);
}

# Validates that +$obj+ inherits from +$type+.
# @see #assert_is_a
sub assert_isa { goto &assert_is_a }

# Validates that the given +$string+ matches the given +$pattern+.
#
# @example
#   assert_match 'Four score and seven years ago...', qr/score/;
#
# @param [String] $string The string to match.
# @param [Regex] $pattern The regular expression to match against.
# @param [String] $msg (undef) An optional description.
sub assert_match ($$;$) {
    my ($string, $pattern, $msg) = @_;
    $msg = message("Expected qr/$pattern/ to match against @{[inspect($string)]}", $msg);
    assert($string =~ $pattern, $msg);
}

# Validates that the given +$string+ does not match the given +$pattern+.
#
# @example
#   refute_match 'Four score and seven years ago...', qr/score/;
#
# @param [String] $string The string to match.
# @param [Regex] $pattern The regular expression to match against.
# @param [String] $msg (undef) An optional description.
sub refute_match ($$;$) {
    my ($string, $pattern, $msg) = @_;
    $msg = message("Expected qr/$pattern/ to fail to match against @{[inspect($string)]}", $msg);
    refute($string =~ $pattern, $msg);
}

# Verifies that the given +$obj+ is capable of responding to the given
# +$method+ name.
# @see #assert_can
sub assert_responds_to ($$;$) { goto &assert_can }

# Verifies that the given +$obj+ is *not* capable of responding to the given
# +$method+ name.
# @see #refute_can
sub refute_responds_to ($$;$) { goto &refute_can }

# Validates that the given +$obj+ is undefined.  Aliased as {#refute_defined}.
#
# @example
#   assert_undef $value;  # if not defined $value
#
# @param $obj The value to check.
# @param [String] $msg (undef) An optional description.
sub assert_undef ($;$) {
    my ($obj, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} to be undefined", $msg);
    refute(defined $obj, $msg);
}

# Validates that the given +$obj+ is defined.  Aliased as {#assert_defined}.
#
# @example
#   refute_undef $value;  # if defined $value
#
# @param $obj The value to check.
# @param [String] $msg (undef) An optional description.
sub refute_undef ($;$) {
    my ($obj, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} to be defined", $msg);
    assert(defined $obj, $msg);
}

# Allows the current test to be bypassed with an indeterminate status.
# @param [String] $msg (undef) An optional description.
sub skip (;$) {
    my ($msg) = @_;
    $msg = 'Test skipped; no message given.' unless defined $msg;
    $msg = $msg->() if ref $msg eq 'CODE';
    Test::Mini::Exception::Skip->throw(
        message        => $msg,
        ignore_package => [__PACKAGE__],
    );
}

# Causes the current test to exit immediately with a failing status.
# @param [String] $msg (undef) An optional description.
sub flunk (;$) {
    my ($msg) = @_;
    $msg = 'Epic failure' unless defined $msg;
    assert(0, $msg);
}

1;
