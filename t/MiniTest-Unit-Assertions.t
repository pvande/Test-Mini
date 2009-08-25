use MiniTest::Unit;

{ package Mock::Bag; use Moose; }

testcase Assertions
{
  sub assert_passes(&)
  {
    my $result = 0;
    MiniTest::Unit::Assertions->meta->add_method(assert => sub {
      my ($class, $test, $msg) = @_;
      $result += !$test;
    });
    shift->();
    refute($result, 'test should have passed');
  }

  sub assert_fails(&)
  {
    my $result = 0;
    MiniTest::Unit::Assertions->meta->add_method(assert => sub {
      my ($class, $test, $msg) = @_;
      $result += !!$test;
    });
    shift->();
    assert($result, 'test should have failed');
  }

  sub assert_error(&)
  {
    MiniTest::Unit::Assertions->meta->add_method(assert => sub {});
    eval { shift->() };
    assert(Exception::Class->caught(), "test should have raised error");
  }


  assert_block: {
    test assert_block_with_truthy_block
    {
      assert_passes {
        MiniTest::Unit::Assertions->assert_block(sub { 1 }, 'assert_block');
      };
    }

    test assert_block_with_falsey_block
    {
      assert_fails {
        MiniTest::Unit::Assertions->assert_block(sub { 0 }, 'assert_block');
      };
    }

    test assert_block_with_block_that_dies
    {
      assert_error {
        MiniTest::Unit::Assertions->assert_block(sub { die }, 'assert_block');
      };
    }

    test assert_block_with_truthy_block_reversed_arguments
    {
      assert_passes {
        MiniTest::Unit::Assertions->assert_block('assert_block', sub { 1 });
      };
    }

    test assert_block_with_falsey_block_reversed_arguments
    {
      assert_fails {
        MiniTest::Unit::Assertions->assert_block('assert_block', sub { 0 });
      };
    }

    test assert_block_with_block_that_dies_reversed_arguments
    {
      assert_error {
        MiniTest::Unit::Assertions->assert_block('assert_block', sub { die });
      };
    }
  }

  assert_empty: {
    test assert_empty_with_empty_arrayref
    {
      assert_passes {
        MiniTest::Unit::Assertions->assert_empty([])
      };
    }

    test assert_empty_with_empty_hashref
    {
      assert_passes {
        MiniTest::Unit::Assertions->assert_empty({})
      };
    }

    test assert_empty_with_empty_string
    {
      assert_passes {
        MiniTest::Unit::Assertions->assert_empty('')
      };
    }

    test assert_empty_with_empty_object
    {
      Mock::Bag->meta->add_method(is_empty => sub { 1 });

      assert_passes {
        MiniTest::Unit::Assertions->assert_empty(Mock::Bag->new())
      };
    }

    test assert_empty_with_nonempty_arrayref
    {
      assert_fails {
        MiniTest::Unit::Assertions->assert_empty([ undef ])
      };
    }

    test assert_empty_with_nonempty_hashref
    {
      assert_fails {
        MiniTest::Unit::Assertions->assert_empty({ undef => undef })
      };
    }

    test assert_empty_with_nonempty_string
    {
      assert_fails {
        MiniTest::Unit::Assertions->assert_empty('a')
      };
    }

    test assert_empty_with_nonempty_object
    {
      Mock::Bag->meta->add_method(is_empty => sub { 0 });

      assert_fails {
        MiniTest::Unit::Assertions->assert_empty(Mock::Bag->new())
      };
    }
  }

  test assert_equal_with_numbers
  {
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal(0, 0, 'assert_equal');
    };
  }

  test assert_equal_with_strings
  {
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal('foo', lc('FOO'), 'assert_equal');
    };
  }

  test assert_equal_with_number_like_strings
  {
    assert_passes {
      MiniTest::Unit::Assertions->assert_equal('inf', 'INFINITY', 'assert_equal');
    };
  }
}