use Test::More tests => 58;
use strict;
use warnings;

BEGIN {
    require_ok 'Test::Mini::Unit::Sugar::TestCase';
    Test::Mini::Unit::Sugar::TestCase->import();
}

can_ok __PACKAGE__, 'testcase';
ok !__PACKAGE__->can('test');
ok !__PACKAGE__->can('setup');
ok !__PACKAGE__->can('teardown');

is(__PACKAGE__, 'main');

# Testing top-level class names
testcase TestCase {
    main::is(__PACKAGE__, 'TestCase');
    main::can_ok(__PACKAGE__, qw/ test setup teardown /);

    our $setup_calls = 0;
    our $test_calls  = 0;

    setup {
        main::isa_ok $self, __PACKAGE__;
        main::note 'first #setup called for ' . $self->{name};
        main::is $setup_calls, 0, 'first #setup called first';
        $setup_calls++;
    }

    setup {
        main::isa_ok $self, __PACKAGE__;
        main::note 'second #setup called for ' . $self->{name};
        main::is $setup_calls, 1, 'second #setup called second';
        $setup_calls++;
    }

    test something {
        main::note 'test_something called';
        main::isa_ok $self, __PACKAGE__;
        main::is $setup_calls, 2;
        main::is $test_calls, 0;

        $setup_calls -= 2;
        $test_calls +=2;
    }

    test something_else {
        main::note 'test_something_else called';
        main::isa_ok $self, __PACKAGE__;
        main::is $setup_calls, 2;
        main::is $test_calls, 0;

        $setup_calls -= 2;
        $test_calls += 2;
    }

    teardown {
        main::isa_ok $self, __PACKAGE__;
        main::note 'first #teardown called for ' . $self->{name};
        main::is $test_calls, 1, 'first #teardown called last';
        $test_calls--;
    }

    teardown {
        main::isa_ok $self, __PACKAGE__;
        main::note 'second #teardown called for ' . $self->{name};
        main::is $test_calls, 2, 'second #teardown called before first';
        $test_calls--;
    }

    END { main::is $TestCase::test_calls, 0 }
};
is(__PACKAGE__, 'main');

# Testing namespaced class names
testcase Test::Case {
    main::is(__PACKAGE__, 'Test::Case');
    main::can_ok(__PACKAGE__, qw/ test setup teardown /);

    our $setup_calls = 0;
    our $test_calls  = 0;

    setup {
        main::isa_ok $self, __PACKAGE__;
        main::note 'first #setup called for ' . $self->{name};
        main::is $setup_calls, 0, 'first #setup called first';
        $setup_calls++;
    }

    setup {
        main::isa_ok $self, __PACKAGE__;
        main::note 'second #setup called for ' . $self->{name};
        main::is $setup_calls, 1, 'second #setup called second';
        $setup_calls++;
    }

    test something {
        main::note 'test_something called';
        main::isa_ok $self, __PACKAGE__;
        main::is $setup_calls, 2;
        main::is $test_calls, 0;

        $setup_calls -= 2;
        $test_calls +=2;
    }

    test something_else {
        main::note 'test_something_else called';
        main::isa_ok $self, __PACKAGE__;
        main::is $setup_calls, 2;
        main::is $test_calls, 0;

        $setup_calls -= 2;
        $test_calls += 2;
    }

    teardown {
        main::isa_ok $self, __PACKAGE__;
        main::note 'first #teardown called for ' . $self->{name};
        main::is $test_calls, 1, 'first #teardown called last';
        $test_calls--;
    }

    teardown {
        main::isa_ok $self, __PACKAGE__;
        main::note 'second #teardown called for ' . $self->{name};
        main::is $test_calls, 2, 'second #teardown called before first';
        $test_calls--;
    }

    END { main::is $Test::Case::test_calls, 0 }
};
is(__PACKAGE__, 'main');

use Test::Mini::Runner;
Test::Mini::Runner->new(logger => 'Test::Mini::Logger')->run();

END {
    # Cleanup, so that others aren't polluted if run in the same process.
    @TestCase::ISA = ();
    @Test::Case::ISA = ();
}
