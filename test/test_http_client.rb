require_relative "helper"

class TestHttpClient < MiniTest::Test
  def setup
    @http = stub(:fake_http)
    @http.stubs(:set_auth)

    options = {'fake_param' => 'fake_param_value'}

    logger = stub(:fake_logger)
    logger.stubs(:debug?).returns(false)

    login_url = "fake rets url"

    @client = Rets::HttpClient.new(@http, options, logger, login_url)
  end

  def test_http_get_delegates_to_client
    url = 'foo@example.com'
    response = stub(:response)
    response.stubs(:body).returns('response data')

    @http.stubs(:get).with(url, anything, anything).returns(response)

    assert_equal @client.http_get(url, {}), response
  end

  def test_http_post_delegates_to_client
    url = 'foo@example.com'
    response = stub(:response)
    response.stubs(:body).returns('response data')

    @http.stubs(:post).with(url, anything, anything).returns(response)

    assert_equal @client.http_post(url, {}), response
  end
end
