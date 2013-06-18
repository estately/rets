require_relative "helper"

class TestLockingHttpClient < MiniTest::Test
  def setup
    @fake_client = stub('fake_client')
    @locker = stub('locker')
    @locking_client = Rets::LockingHttpClient.new(@fake_client, @locker, 'lock_name')
    @url = "fake rets url"
    @params = {'fake_param' => 'fake_param_value'}
  end

  def test_locking_client_calls_the_real_client_if_lock_succeeds
    @locker.stubs(:lock).with('lock_name', {}).yields(nil)
    @fake_client.expects(:http_post).with(@url, @params, {})
    @locking_client.http_post(@url, @params)
  end

  def test_locking_client_does_nothing_if_lock_fails_to_yield
    @fake_client.expects(:http_post).never
    @locker.stubs(:lock).with('lock_name', {})
    @locking_client.http_post(@url, @params)
  end

  def test_locking_client_returns_result_from_client
    @fake_client.stubs(:http_post).returns('result')
    @locker.stubs(:lock).with('lock_name', {}).yields(nil)
    assert_equal 'result', @locking_client.http_post(@url, @params)
  end
end
