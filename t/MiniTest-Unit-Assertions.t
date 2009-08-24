use MiniTest::Unit;

testcase Assertions
{
  sub assert_passes
  {
    MiniTest::Unit::Assertions->meta->add_method(assert => sub {
      my ($class, $test, $msg) = @_;
      $msg = $msg->() if ref $msg eq 'CODE';
      assert(!!$test, "test should have passed - $msg");
    });
    shift->();
  }

  test assert_equal_with_numbers
  {
    assert_passes sub {
      MiniTest::Unit::Assertions->assert_equal(0, 0, 'assert_equal');
    }
  }

  test assert_equal_with_strings
  {
    assert_passes sub {
      MiniTest::Unit::Assertions->assert_equal('foo', lc('FOO'), 'assert_equal');
    }
  }

  test assert_equal_with_number_like_strings
  {
    assert_passes sub {
      MiniTest::Unit::Assertions->assert_equal('Inf', 'infinity', 'assert_equal');
    }
  }
}