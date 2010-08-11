package VintageTest;

use Test::Mini::Assertions;
use base 'Test::Mini::Unit::TestCase';

sub setup    { 'This runs before each test...' }
sub teardown { 'This runs after each test...' }

sub test_assert { assert 1, 'I should pass' }
sub test_refute { refute 0, 'I should fail' }
sub test_skip   { skip "I've got better things to do" }

1;

use Test::Mini::Unit::Runner;
exit Test::Mini::Unit::Runner->new()->run();