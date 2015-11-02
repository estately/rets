require_relative "helper"

class TestLockingCookieSaver < MiniTest::Test
  def setup
    @cookie_saver = Rets::LockingCookieSaver.new
    @cookie_jar = HTTP::CookieJar.new
  end

  def test_acquires_shared_lock_for_reading
    HTTPClient::WebAgentSaver.any_instance.expects(:load)

    File.open('/dev/null', 'r') do |f|
      f.expects(:flock).with(File::LOCK_SH)

      @cookie_saver.load(f, @cookie_jar)
    end
  end

  def test_acquires_exclusive_lock_for_writing
    HTTPClient::WebAgentSaver.any_instance.expects(:save)

    File.open('/dev/null', 'w') do |f|
      f.expects(:flock).with(File::LOCK_EX)

      @cookie_saver.save(f, @cookie_jar)
    end
  end
end
