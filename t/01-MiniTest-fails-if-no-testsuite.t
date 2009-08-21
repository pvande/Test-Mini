# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MiniTest-Unit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
END   { $? = 0 if is $?, 255 };
BEGIN { use_ok('MiniTest::Unit') };