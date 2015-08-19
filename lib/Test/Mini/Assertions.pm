#
# First we define some cuckoo packages that we're going to use
#
package Test::Mini::Exception;
use parent -norequire, 'Exception::Class::Base';

package Test::Mini::Exception::Assert;
use parent -norequire, 'Test::Mini::Exception';

package Test::Mini::Exception::Skip;
use parent -norequire, 'Test::Mini::Exception::Assert';

#
# And then we have the module proper itself
#
# Basic Assertions for Test::Mini.
#
package Test::Mini::Assertions;
use 5.006;
use strict;
use warnings;

use Scalar::Util      qw/ looks_like_number refaddr reftype /;
use List::Util        qw/ min any /;
use Data::Inspect;

# Formats error messages,
# appending periods and defaulting undefs as appropriate.
sub message {
    my ($default, $msg) = @_;

    $msg .= $msg ? ".\n" : '';
    $msg .= "$default.";

    return sub { return $msg };
}

# Dereferences the given argument, if possible.
sub deref {
    my ($ref) = @_;
    return %$ref if reftype($ref) eq 'HASH';
    return @$ref if reftype($ref) eq 'ARRAY';
    return $$ref if reftype($ref) eq 'SCALAR';
    return $$ref if reftype($ref) eq 'REF';
    return refaddr($ref);
}

# Produce a more useful string representation of the given argument.
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
sub _reset_assertions {
    my $final_count = $assertion_count;
    $assertion_count = 0;
    return $final_count;
}

# ========================
# Exported Functions
# ========================

# Assert that $test is truthy, and throw a Test::Mini::Exception::Assert
# if that assertion fails.
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

# Asserts that $test is falsey, and throw a Test::Mini::Exception::Assert
# if that assertion fails.
sub refute ($;$) {
    my ($test, $msg) = @_;
    $msg ||= 'Refutation failed; no message given.';
    return assert(!$test, $msg);
}

# Asserts that the given code reference returns a truthy value.
# DEPRECATED - this will be removed in v2.0.0.
sub assert_block (&;$) {
    my ($block, $msg) = @_;
    warn '#assert_block is deprecated; please use #assert instead.';
    ($msg, $block) = ($block, $msg) if $msg && ref $block ne 'CODE';
    $msg = message('Expected block to return true value', $msg);
    assert_instance_of($block, 'CODE');
    assert($block->(), $msg);
}

# Asserts that the given code reference returns a falsey value.
# DEPRECATED - this will be removed in v2.0.0.
sub refute_block (&;$) {
    my ($block, $msg) = @_;
    warn '#refute_block is deprecated; please use #refute instead.';
    ($msg, $block) = ($block, $msg) if $msg && ref $block ne 'CODE';
    $msg = message('Expected block to return false value', $msg);
    assert_instance_of($block, 'CODE');
    refute($block->(), $msg);
}

# Verifies that the given $obj is capable of responding to the given
# $method name.
sub assert_can ($$;$) {
    my ($obj, $method, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} (@{[ref $obj || 'SCALAR']}) to respond to #$method", $msg);
    assert($obj->can($method), $msg);
}

# Verifies that the given $obj is *not* capable of responding to the given
# $method name.
sub refute_can ($$;$) {
    my ($obj, $method, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} (@{[ref $obj || 'SCALAR']}) to not respond to #$method", $msg);
    refute($obj->can($method), $msg);
}

# Verifies that the given $collection contains the given $obj as a member.
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

# Verifies that the given $collection does not contain the given $obj as a
# member.
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

# Validates that the given $obj is defined.
sub assert_defined ($;$) {
    my ($obj, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} to be defined", $msg);
    assert(defined $obj, $msg);
}

# Validates that the given $obj is not defined.
sub refute_defined ($;$) { goto &assert_undef }

# Tests that the supplied code block dies, and fails if it succeeds.  If
# $error is provided, the error message in $@ must contain it.
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
sub assert_eq { goto &assert_equal }

# Checks two given arguments for inequality.
sub refute_eq { goto &refute_equal }

# Checks two given arguments for equality.
sub assert_equal ($$;$) {
    my ($actual, $expected, $msg) = @_;
    $msg = message("Got @{[inspect($actual)]}\nnot @{[inspect($expected)]}", $msg);

    my @expected = ($expected);
    my @actual   = ($actual);

    my $passed = 1;

    while ($passed && (@actual || @expected)) {
        ($actual, $expected) = (shift(@actual), shift(@expected));

        next if ref $actual && ref $expected && refaddr($actual) == refaddr($expected);

        if (eval { $expected->can('equals') }) {
            $passed = $expected->equals($actual);
        }
        elsif (ref $actual eq 'ARRAY' && ref $expected eq 'ARRAY') {
            $passed = (@$actual == @$expected);
            unshift @actual, @$actual;
            unshift @expected, @$expected;
        }
        elsif (ref $actual eq 'HASH' && ref $expected eq 'HASH') {
            $passed = (keys %$actual == keys %$expected);
            unshift @actual,   map {$_, $actual->{$_}  } sort keys %$actual;
            unshift @expected, map {$_, $expected->{$_}} sort keys %$expected;
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

# Checks two given arguments for inequality.
sub refute_equal ($$;$) {
    my ($actual, $unexpected, $msg) = @_;
    $msg = message("The given values were unexpectedly equal", $msg);

    my @unexpected = ($unexpected);
    my @actual   = ($actual);

    my $passed = 1;

    while ($passed && (@actual || @unexpected)) {
        ($actual, $unexpected) = (shift(@actual), shift(@unexpected));

        next if ref $actual && ref $unexpected && refaddr($actual) == refaddr($unexpected);

        if (eval { $unexpected->can('equals') }) {
            $passed = $unexpected->equals($actual);
        }
        elsif (ref $actual eq 'ARRAY' && ref $unexpected eq 'ARRAY') {
            $passed = (@$actual == @$unexpected);
            unshift @actual, @$actual;
            unshift @unexpected, @$unexpected;
        }
        elsif (ref $actual eq 'HASH' && ref $unexpected eq 'HASH') {
            $passed = (keys %$actual == keys %$unexpected);
            unshift @actual,     map {$_, $actual->{$_}} sort keys %$actual;
            unshift @unexpected, map {$_, $unexpected->{$_}} sort keys %$unexpected;
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

# Checks that the difference between $actual and $expected is less than
# $delta.
sub assert_in_delta ($$;$$) {
    my ($actual, $expected, $delta, $msg) = @_;
    $delta = 0.001 unless defined $delta;
    my $n = abs($actual - $expected);
    $msg = message("Expected $actual - $expected ($n) to be < $delta", $msg);
    assert($delta >= $n, $msg);
}

# Checks that the difference between $actual and $expected is greater than
# $delta.
sub refute_in_delta ($$;$$) {
    my ($actual, $expected, $delta, $msg) = @_;
    $delta = 0.001 unless defined $delta;
    my $n = abs($actual - $expected);
    $msg = message("Expected $actual - $expected ($n) to be > $delta", $msg);
    refute($delta >= $n, $msg);
}

# Checks that the difference between $actual and $expected is less than
# a given fraction of the smaller of the two numbers.
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

# Checks that the difference between $actual and $expected is greater than
# a given fraction of the smaller of the two numbers.
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

# Verifies that the given $collection contains the given $obj as a member.
sub assert_includes ($$;$) { goto &assert_contains }

# Verifies that the given $collection does not contain the given $obj as a
# member.
sub refute_includes ($$;$) { goto &refute_contains }

# Validates that the given object is an instance of $type.
sub assert_instance_of ($$;$) {
    my ($obj, $type, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} to be an instance of $type, not @{[ref $obj]}", $msg);
    assert(ref $obj eq $type, $msg);
}

# Validates that $obj inherits from $type.
sub assert_is_a($$;$) {
    my ($obj, $type, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} to inherit from $type", $msg);
    assert($obj->isa($type), $msg);
}

# Validates that $obj inherits from $type.
sub assert_isa { goto &assert_is_a }

# Validates that the given $string matches the given $pattern.
sub assert_match ($$;$) {
    my ($string, $pattern, $msg) = @_;
    $msg = message("Expected qr/$pattern/ to match against @{[inspect($string)]}", $msg);
    assert($string =~ $pattern, $msg);
}

# Validates that the given $string does not match the given $pattern.
sub refute_match ($$;$) {
    my ($string, $pattern, $msg) = @_;
    $msg = message("Expected qr/$pattern/ to fail to match against @{[inspect($string)]}", $msg);
    refute($string =~ $pattern, $msg);
}

# Verifies that the given $obj is capable of responding to the given
# $method name.
sub assert_responds_to ($$;$) { goto &assert_can }

# Verifies that the given $obj is *not* capable of responding to the given
# $method name.
sub refute_responds_to ($$;$) { goto &refute_can }

# Validates that the given $obj is undefined.
sub assert_undef ($;$) {
    my ($obj, $msg) = @_;
    $msg = message("Expected @{[inspect($obj)]} to be undefined", $msg);
    refute(defined $obj, $msg);
}

# Validates that the given $obj is not undefined.
sub refute_undef ($;$) { goto &assert_defined }

# Allows the current test to be bypassed with an indeterminate status.
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
sub flunk (;$) {
    my ($msg) = @_;
    $msg = 'Epic failure' unless defined $msg;
    assert(0, $msg);
}

1;

__END__

=head1 NAME

Test::Mini - base assertions for Test::Mini

=head1 SYNOPSIS

 use Test::Mini::Assertions;

 assert($day_of_week eq 'Friday', 'Test should only be run on Friday!');

=head1 DESCRIPTION

This module provides a number of assertion functions,
which are imported into your namespace when you use the module.

All of these functions take an optional final argument, C<$msg>,
which will be used as the text of the assertion, if specified.

=head1 EXPORTED FUNCTIONS

=head2 assert($test, $msg)

Asserts that C<$test> is truthy,
and throws a L<Test::Mini::Exception::Assert> if that assertion fails.
For example:

 assert 1;
 assert 'true', 'Truth should shine clear';


=head2 assert_block($block, $msg)

Deprecated, as this function offers little advantage over the
C<assert()> function, described above.

Asserts that the given code reference returns a truthy value.
For example:

 assert_block { 'true' };

 assert_block \&some_sub, 'expected better from &some_sub';


=head2 assert_can($obj, $method, $msg)

Verifies that the given C<$obj>
is capable of responding to the given C<$method> name.

Examples:

 assert_can $date, 'day_of_week';
 
 assert_can $time, 'seconds', '$time cannot respond to #seconds';

This function is aliased as function C<assert_responds_to()>.


=head2 assert_contains($collection, $obj, $msg)

Verifies that the given C<$collection> contains the given C<$obj> as a member.

Examples:

 assert_contains [qw/ 1 2 3 /], 2;
 assert_contains { a => 'b' }, 'a';  # 'b' also contained
 assert_contains 'expectorate', 'xp';
 assert_contains Collection->new(1, 2, 3), 2;  # if Collection->contains(2)

The first argument, C<$collection>, can be an array, a hash,
a string, or an object that provides a C<contains> method.

This function is aliased as C<assert_includes()>.


=head2 assert_defined($obj, $msg)

Validates that the given C<$obj> is defined.

Example:

 assert_defined $value;

This function is aliased as C<refute_undef()>.


=head2 assert_dies($sub, $error, $msg)

Tests that the supplied code block dies, and fails if it succeeds.
If C<$error> is provided, the error message in C<$@> must contain it.

Examples:

 assert_dies { die 'LAGHLAGHLAGHL' };
 assert_dies { die 'Failure on line 27 in Foo.pm' } 'line 27';


=head2 assert_empty($collection, $msg)

Verifies the emptiness of a collection.

Examples:

 assert_empty [];
 assert_empty {};
 assert_empty '';
 assert_empty Collection->new();  # if Collection->new()->is_empty()


=head2 assert_equal($actual, $expected, $msg)

Checks two given arguments for equality.
The first argument, C<$actual>, is the value being tested
(eg has been calculated by code under test),
and the second argument gives the expected value.

Examples:

 assert_equal 3.000, 3;
 assert_equal lc('FOO'), 'foo';
 assert_equal [qw/ 1 2 3 /], [ 1, 2, 3 ];
 assert_equal { a => 'eh' }, { a => 'eh' };

 # if $expected->equals(Class->new())
 assert_equal Class->new(), $expected;

This function is also aliased as C<assert_eq()>.


=head2 assert_in_delta($actual, $expected, $delta, $msg)

Checks that the difference between C<$actual> and C<$expected>
is less than C<$delta>.

Examples:

 assert_in_delta 1.001, 1;
 assert_in_delta 104, 100, 5;


=head2 assert_in_epsilon($actual, $expected, $epsilon, $msg)

Checks that the difference between C<$actual> and C<$expected>
is less than a given fraction of the smaller of the two numbers.

Examples:

 assert_in_epsilon 22.0 / 7.0, Math::Trig::pi;
 assert_in_epsilon 220, 200, 0.10;

If C<$epsilon> isn't given, it defaults to 0.001.


=head2 assert_instance_of($object, $type, $msg)

Validates that the given C<$object> is an instance of C<$type>.

Examples:

 my $object = MyApp::Person->new();
 assert_instance_of $object, 'MyApp::Person';


=head2 assert_is_a($obj, $type, $msg)

Validates that C<$obj> inherits from C<$type>.

Examples:

 assert_is_a 'Employee', 'Employee';
 assert_is_a Employee->new(), 'Employee';
 assert_is_a 'Employee', 'Person'; # assuming Employee->isa('Person')
 assert_is_a Employee->new(), 'Person';

This function is also available as C<assert_isa()>.


=head2 assert_match($string, $pattern, $msg)

Validates that the given C<$string> matches the given C<$pattern>.

Examples:

 assert_match 'Four score and seven years ago...', qr/score/;


=head2 assert_undef($obj, $msg)

Validates that the given C<$obj> is undefined.

Examples:

 assert_undef $value;  # if not defined $value

Also available as C<refute_defined()>.


=head2 flunk($msg)

Causes the current test to exit immediately with a failing status.


=head2 refute($test, $msg)

Asserts that C<$test> is falsey,
and throws a L<Test::Mini::Exception::Assert> if that assertion fails.

Examples:

 refute 0;
 refute undef, 'Deny the untruths';


=head2 refute_block($block, $msg) 
  
B<Deprecated>:
This assertion offers little advantage over the base C<refute()>.
This will be removed in v2.0.0.

Asserts that the given code reference returns a falsey value.

Examples:

 refute_block { '' };
 refute_block \&some_sub, 'expected worse from &some_sub';


=head2 refute_can($obj, $method, $msg)

Verifies that the given C<$obj> is not capable of responding
to the given C<$method> name.

Examples:

 refute_can $date, 'to_time';
 refute_can $time, 'day', '$time cannot respond to #day';

Also available as C<refute_responds_to()>.


=head2 refute_contains($collection, $obj, $msg)

Verifies that the given C<$collection> does not contain the given
C<$obj> as a member.

Examples:

 refute_contains [qw/ 1 2 3 /], 5;
 refute_contains { a => 'b' }, 'x';
 refute_contains 'expectorate', 'spec';
 refute_contains Collection->new(1, 2, 3), 5;  # unless Collection->contains(5)

The C<$collection> can be a hash ref, an array ref, a string,
or an instance of a class that provides a C<contains()> method.


=head2 refute_empty($collection, $msg)

Verifies the non-emptiness of a collection.

Examples:

 refute_empty [ 1 ];
 refute_empty { a => 1 };
 refute_empty 'full';
 refute_empty Collection->new();  # unless Collection->new()->is_empty()

See the description for C<refute_contains()> above for
what C<$collection> can be.


=head2 refute_equal($actual, $unexpected, $msg)

Checks two given arguments for inequality.

Examples:

 refute_equal 3.001, 3;
 refute_equal lc('FOOL'), 'foo';
 refute_equal [qw/ 1 23 /], [ 1, 2, 3 ];
 refute_equal { a => 'ae' }, { a => 'eh' };
 refute_equal Class->new(), $expected;  # unless $expected->equals(Class->new())

Also available as C<refute_eq()>.


=head2 refute_in_delta($actual, $expected, $delta, $msg)

Checks that the difference between C<$actual> and C<$expected>
is greater than C<$delta>.

Examples:

 refute_in_delta 1.002, 1;
 refute_in_delta 106, 100, 5;


=head2 refute_in_epsilon($actual, $expected, $epsilon, $msg)

Checks that the difference between C<$actual> and C<$expected>
is greater than a given fraction of the smaller of the two numbers.

Examples:

 refute_in_epsilon 21.0 / 7.0, Math::Trig::pi;
 refute_in_epsilon 220, 200, 0.20


=head2 refute_match($string, $pattern, $msg)

Validates that the given C<$string> does not match the given C<$pattern>.

Examples:

 refute_match 'Four score and seven years ago...', qr/score/;


=head2 skip($msg)

Allows the current test to be bypassed with an indeterminate status.


=head1 SEE ALSO

L<Test::Mini>

=head1 REPOSITORY

L<https://github.com/pvande/Test-Mini>

=head1 AUTHOR

Pieter van de Bruggen E<lt>pvande@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pieter van de Bruggen
E<lt>pvande@cpan.orgE<gt>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

