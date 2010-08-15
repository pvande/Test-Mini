package VintageTest;
use base 'Test::Mini::TestCase';

use Test::Mini;
use Test::Mini::Assertions;

sub setup    { 'This runs before each test...' }
sub teardown { 'This runs after each test...' }

sub test_assert { assert 1, 'I should pass' }
sub test_refute { refute 0, 'I should fail' }
sub test_skip   { skip "I've got better things to do" }

1;
