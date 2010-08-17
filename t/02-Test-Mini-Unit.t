use Test::More tests => 3;
use strict;
use warnings;

use Test::Mini::Unit;
can_ok __PACKAGE__, 'testcase';

BEGIN {
    use_ok 'Test::Mini::Unit';
    use List::Util qw/ first /;
    use B qw/ end_av /;

    my $index = first {
        my $cv = end_av->ARRAYelt($_);
        ref $cv eq 'B::CV' && $cv->STASH->NAME eq 'Test::Mini';
    } 0..(end_av->MAX);

    ok defined($index), 'END hook installed';

    splice(@{ end_av()->object_2svref() }, $index, 1);
}
