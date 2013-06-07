require 'helper'

class TestLockingClient < MiniTest::Test
  def setup
    @fake_client = stub('fake_client')
    @locker = stub('locker')
    @locking_client = Rets::LockingClient.new(@fake_client, @locker, 'lock_name')
  end

  def test_locking_client_calls_the_real_client_if_lock_succeeds
    @locker.stubs(:lock).with('lock_name', {}).yields(nil)
    @fake_client.expects(:login)
    @locking_client.login
  end

  def test_locking_client_does_nothing_if_lock_fails_to_yield
    @fake_client.expects(:login).never
    @locker.stubs(:lock).with('lock_name', {})
    @locking_client.login
  end

  def test_locking_client_returns_result_from_client
    @fake_client.stubs(:login).returns('result')
    @locker.stubs(:lock).with('lock_name', {}).yields(nil)
    assert_equal 'result', @locking_client.login
  end
end
