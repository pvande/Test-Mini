use Test::More tests => 6;

{
    package Foo;
    use Test::Mini::Unit::Sugar::Test;
}

can_ok Foo => 'test';

{
    package Foo;
    test everything { return 42 }
}

can_ok Foo => 'test_everything';

{
    package Foo;
    test myself { return $self }
}

is Foo::test_myself('FIRST'), 'FIRST', '&Foo::test automatically sets up $self';

{
    package Y;
    use Test::Mini::Unit::Sugar::Test (into => 'X');
}

ok ! Y->can('test');
can_ok X => 'test';

{
    package X;
    test something { }
}

can_ok X => 'test_something';

1;
