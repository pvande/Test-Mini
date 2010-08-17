use Test::More tests => 25;

BEGIN {
    require_ok Test::Mini::Unit::Sugar::Advice;
    eval {
        package Foo;
        Test::Mini::Unit::Sugar::Advice->import();
    };
    ok $@;
}

{
    note 'Testing top-level packages...';
    {
        package Foo;
        use Test::Mini::Unit::Sugar::Advice name => 'advice';
    }

    can_ok Foo => 'advice';

    $Foo = { advice => [] };

    {
        package Foo;
        advice { main::ok 1; return 0 }
    }

    is scalar(@{$Foo->{advice}}), 1;
    isa_ok $Foo->{advice}->[0], 'CODE';
    is $Foo->{advice}->[0]->(), 0;

    {
        package Foo;
        advice { main::ok 1; return 1 }
    }

    is scalar(@{$Foo->{advice}}), 2;
    isa_ok $Foo->{advice}->[1], 'CODE';
    is $Foo->{advice}->[1]->(), 1;
}

{
    note 'Testing namespaced packages';
    {
        package Foo::Bar;
        use Test::Mini::Unit::Sugar::Advice name => 'advice';
    }

    can_ok 'Foo::Bar' => 'advice';

    $Foo::Bar = { advice => [] };

    {
        package Foo::Bar;
        advice { main::ok 1; return 0 }
    }

    is scalar(@{$Foo::Bar->{advice}}), 1;
    isa_ok $Foo::Bar->{advice}->[0], 'CODE';
    is $Foo::Bar->{advice}->[0]->(), 0;

    {
        package Foo::Bar;
        advice { main::ok 1; return 1 }
    }

    is scalar(@{$Foo::Bar->{advice}}), 2;
    isa_ok $Foo::Bar->{advice}->[1], 'CODE';
    is $Foo::Bar->{advice}->[1]->(), 1;
}

{
    package Y;
    use Test::Mini::Unit::Sugar::Advice into => 'X', name => 'advice';
}

ok ! Y->can('advice');
can_ok X => 'advice';

$X = { advice => [ ] };

{
    package X;
    advice { pass; return 0 }
}

is length(@{$X->{advice}}), 1;
isa_ok $X->{advice}->[0], 'CODE';
is $X->{advice}->[0]->(), 0;

1;
