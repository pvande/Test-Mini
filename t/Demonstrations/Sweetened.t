use Test::Mini::Unit;

testcase SweetenedTest
{
  setup    { 'This runs before each test...' }
  teardown { 'This runs after each test...' }

  test assert { assert 1, 'I should pass' }
  test refute { refute 0, 'I should fail' }
  test skip   { skip "I've got better things to do" }
}