package Test::Mini::Unit;
use strict;
use warnings;
use 5.008;

use Test::Mini;
use Test::Mini::Runner;
require Test::Mini::Unit::Sugar::TestCase;

sub import {
    my ($class, @args) = @_;
    my $caller = caller();

    strict->import;
    warnings->import;

    Test::Mini::Unit::Sugar::TestCase->import(into => $caller, @args);
}

1;

__END__
