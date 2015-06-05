require_relative "helper"

class TestHttpClient < MiniTest::Test
  def setup
    @cm = Rets::CookieManager.new

    @http = HTTPClient.new
    @http.cookie_manager = @cm

    @logger = Rets::Client::FakeLogger.new
    @logger.stubs(:debug?).returns(false)

    @http_client = Rets::HttpClient.new(@http, {}, @logger, "http://rets.rets.com/somestate/login.aspx")
  end

  def test_http_cookie_with_webagent_cookie
    cookie1 = "RETS-Session-ID=879392834723043209; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    @cm.parse(cookie1, URI.parse("http://www.rets.rets.com"))

    cookie2 = "Foo=Bar; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    @cm.parse(cookie2, URI.parse("http://www.rets.rets.com"))

    assert_equal "879392834723043209", @http_client.http_cookie('RETS-Session-ID')
  end

  def test_http_cookie_without_webagent_cookie
    assert_equal nil, @http_client.http_cookie('RETS-Session-ID')
  end

  def test_http_get_delegates_to_client
    url = 'foo@example.com'
    response = stub(:response)
    response.stubs(:body).returns('response data')

    @http.stubs(:get).with(url, anything, anything).returns(response)

    assert_equal @http_client.http_get(url, {}), response
  end

  def test_http_post_delegates_to_client
    url = 'foo@example.com'
    response = stub(:response)
    response.stubs(:body).returns('response data')

    @http.stubs(:post).with(url, anything, anything).returns(response)

    assert_equal @http_client.http_post(url, {}), response
  end
end
