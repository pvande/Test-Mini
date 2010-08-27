package t::Test::Mini::Logger;
use base 'Test::Mini::TestCase';
use strict;
use warnings;

use Test::Mini;
use Test::Mini::Assertions;

use aliased 'IO::Scalar'         => 'Buffer';
use aliased 'Test::Mini::Logger' => 'Logger';

my ($buffer, $logger);

sub setup {
    $logger = Logger->new(buffer => Buffer->new(\($buffer = '')));
}

sub test_full_test_run_should_remain_silent {
    $logger->begin_test_suite();
    $logger->begin_test_case('MyClass');
    $logger->begin_test('MyClass', 'm1');
    $logger->pass('MyClass', 'm1');
    $logger->finish_test('MyClass', 'm1', 1);
    $logger->begin_test('MyClass', 'm2');
    $logger->fail('MyClass', 'm2', 'failure message');
    $logger->finish_test('MyClass', 'm2', 2);
    $logger->begin_test('MyClass', 'm3');
    $logger->error('MyClass', 'm3', 'error message');
    $logger->finish_test('MyClass', 'm3', 3);
    $logger->begin_test('MyClass', 'm4');
    $logger->skip('MyClass', 'm4', 'reason');
    $logger->finish_test('MyClass', 'm4', 0);
    $logger->finish_test_case('MyClass', qw/ m1 m2 m3 m4 /);
    $logger->finish_test_suite(1);

    assert_equal $buffer, '';
}

sub test_count {
    $logger->pass('MyClass', 'm1');
    $logger->finish_test('MyClass', 'm1', 8);
    $logger->error('MyClass', 'm2');
    $logger->finish_test('MyClass', 'm2', 7);
    $logger->pass('MyClass', 'm3');
    $logger->finish_test('MyClass', 'm3', 6);

    assert_equal($logger->count, {test => 3, pass => 2, error => 1, assertions => 21});
    assert_equal($logger->count('test'), 3);
    assert_equal($logger->count('pass'), 2);
    assert_equal($logger->count('error'), 1);
    assert_equal($logger->count('assertions'), 21);

    assert_equal($logger->count('daily build of rome'), 0);
}

1;
