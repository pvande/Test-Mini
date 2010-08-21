package Test::Mini;
use strict;
use warnings;
use 5.008;

use Test::Mini::Runner;

END {
    $| = 1;
    return if $?;
    $? = Test::Mini::Runner->new()->run();
}

1;

__END__
