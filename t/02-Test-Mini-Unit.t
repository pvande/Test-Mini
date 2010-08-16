use Test::More tests => 54;
use strict;
use warnings;

use Test::Mini::Unit;
can_ok __PACKAGE__, 'testcase';
ok !__PACKAGE__->can('test');
ok !__PACKAGE__->can('setup');
ok !__PACKAGE__->can('teardown');

# Testing top-level class names
testcase TestCase {
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

# Testing namespaced class names
testcase Test::Case {
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

use Test::Mini::Runner;
Test::Mini::Runner->new(logger => 'Test::Mini::Logger')->run();

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

END {
    # Cleanup, so that others aren't polluted if run in the same process.
    @TestCase::ISA = ();
    @Test::Case::ISA = ();
}
