require_relative "helper"

class TestHttpClient < MiniTest::Test
  def setup
    @cm = WebAgent::CookieManager.new

    @http = HTTPClient.new

    @logger = Rets::Client::FakeLogger.new
    @logger.stubs(:debug?).returns(false)

    @http_client = Rets::HttpClient.new(@http, {}, @logger, "http://rets.rets.com/somestate/login.aspx")
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

class CookieManagement < MiniTest::Test
  def setup
    @logger = Rets::Client::FakeLogger.new
    @logger.stubs(:debug?).returns(false)

    @cm = WebAgent::CookieManager.new
    http = HTTPClient.new
    http.cookie_manager = @cm
    @client = Rets::HttpClient.new(http, {}, nil, "http://rets.rets.com/somestate/login.aspx")
  end

  def teardown
    # Empty cookie jar
    @cm.cookies = []
  end

  def test_http_cookie_with_one_cookie_from_one_domain
    set_cookie = "RETS-Session-ID=879392834723043209; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    @cm.parse(set_cookie, URI.parse("http://www.rets.rets.com"))
    assert_equal "879392834723043209", @client.http_cookie('RETS-Session-ID')
  end

  def test_http_cookie_with_multiple_cookies_from_one_domain
    # NOTE: Cookies are ordered alphabetically by name when retrieving
    set_cookie_1 = "RETS-Session-ID=879392834723043209; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    @cm.parse(set_cookie_1, URI.parse("http://www.rets.rets.com"))

    set_cookie_2 = "Zoo=Bar; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    @cm.parse(set_cookie_2, URI.parse("http://www.rets.rets.com"))

    set_cookie_3 = "Foo=Bar; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    @cm.parse(set_cookie_3, URI.parse("http://www.rets.rets.com"))

    assert_equal "879392834723043209", @client.http_cookie('RETS-Session-ID')
  end

  def test_http_cookie_with_no_cookies_from_domain
    assert_equal nil, @client.http_cookie('RETS-Session-ID')
  end

  def test_save_cookie_store
    cookie_file = Tempfile.new('cookie_file').path

    #setup cookie store
    client_a = Rets::HttpClient.from_options({ cookie_store: cookie_file, login_url: "http://rets.rets.com/somestate/login.aspx" }, @logger)

    #add cookie
    cookie = "RETS-Session-ID=879392834723043209; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    client_a.http.cookie_manager.parse(cookie, URI.parse("http://www.rets.rets.com"))

    #save cookie
    client_a.save_cookie_store

    #create new HTTPCLient with same cookie store
    client_b = Rets::HttpClient.from_options({ cookie_store: cookie_file, login_url: "http://rets.rets.com/somestate/login.aspx" }, @logger)

    #check added cookie exists
    assert_equal "879392834723043209", client_b.http_cookie('RETS-Session-ID')
  end

  def test_creates_cookie_store_if_missing_during_initialization
    cookie_file = Tempfile.new('cookie_file')
    cookie_file_path = cookie_file.path

    #remove cookie store
    cookie_file.unlink

    client = Rets::HttpClient.from_options({cookie_store: cookie_file_path}, @logger)

    #add cookie
    cookie = "RETS-Session-ID=879392834723043209; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    client.http.cookie_manager.parse(cookie, URI.parse("http://www.rets.rets.com"))

    #check added cookie exists
    assert_equal "879392834723043209", client.http_cookie('RETS-Session-ID')
  end

  def test_creates_cookie_store_if_missing_during_save
    cookie_file = Tempfile.new('cookie_file')
    cookie_file_path = cookie_file.path

    client = Rets::HttpClient.from_options({cookie_store: cookie_file_path}, @logger)

    #remove cookie store
    cookie_file.unlink

    #add cookie
    cookie = "RETS-Session-ID=879392834723043209; path=/; domain=rets.rets.com; expires=Wednesday, 31-Dec-2037 12:00:00 GMT"
    client.http.cookie_manager.parse(cookie, URI.parse("http://www.rets.rets.com"))

    #save cookie
    client.save_cookie_store

    #check added cookie exists
    assert_equal "879392834723043209", client.http_cookie('RETS-Session-ID')
  end
end
