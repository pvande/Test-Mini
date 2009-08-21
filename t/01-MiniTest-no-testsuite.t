use Test::More tests => 2;

END   { $? = 0 if is($?, 255, 'Exit code') };
BEGIN { use_ok('MiniTest::Unit') };

push @ARGV, qw/ --logger MiniTest::Unit::Logger::Silent /;
