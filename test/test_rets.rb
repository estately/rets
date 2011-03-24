require "test/unit"
require "mocha"

require "rets"

class TestRets < Test::Unit::TestCase

  def setup
    @client = Rets::Client.new(:login_url => "http://example.com")
  end

  def test_initialize_adds_escaped_username_to_uri
    client = Rets::Client.new(
      :login_url => "http://example.com",
      :username => "bob@example.com")

    assert_equal CGI.escape("bob@example.com"), client.uri.user
    assert_nil client.uri.password
  end

  def test_initialize_adds_escaped_password_to_uri
    client = Rets::Client.new(
      :login_url => "http://example.com",
      :username => "bob",
      :password => "secret@2!")

    assert_equal CGI.escape("secret@2!"), client.uri.password
  end

  def test_initialize_merges_default_options
    client = Rets::Client.new(:login_url => "http://example.com", :foo => true)

    assert client.options.include?(:foo)
  end

  def test_initialize_allows_options_to_be_overridden
    client = Rets::Client.new(:login_url => "http://example.com")
    assert_equal true, client.options[:persistent]

    client = Rets::Client.new(:login_url => "http://example.com", :persistent => false)
    assert_equal false, client.options[:persistent]
  end


  def test_connection_uses_persistent
    assert_kind_of Net::HTTP::Persistent, @client.connection
  end

  def test_connection_uses_net_http
    client = Rets::Client.new(:login_url => "http://example.com", :persistent => false)

    assert_kind_of Net::HTTP, client.connection
    assert_equal "example.com", client.connection.address
    assert_equal 80, client.connection.port
  end


  def test_request
    post = mock()
    post.expects(:body=).with("fake body")

    Net::HTTP::Post.expects(:new).with("/foo", {}).returns(post)

    @client.connection.expects(:request).with(@client.uri, post)

    @client.expects(:handle_cookies)
    @client.expects(:handle_response)

    @client.request("/foo", "fake body")
  end

  def test_request_with_block
    # TODO
  end

  def test_request_passes_correct_arguments_to_persistent_connection
    @client.connection.expects(:request).with(@client.uri, instance_of(Net::HTTP::Post))

    @client.stubs(:handle_cookies)
    @client.stubs(:handle_response)

    @client.request("/foo")
  end

  def test_request_passes_correct_arguments_to_net_http_connection
    client = Rets::Client.new(:login_url => "http://example.com", :persistent => false)

    client.connection.expects(:request).with(instance_of(Net::HTTP::Post))

    client.stubs(:handle_cookies)
    client.stubs(:handle_response)

    client.request("/foo")
  end


  def test_handle_cookies
  end

  def test_cookies?
    assert @client.cookies?({"set-cookie" => "FavoriteFruit=Plum;"})
    assert !@client.cookies?({})
  end

  def test_cookies=
    @client.cookies = ["abc=123; path=/; HttpOnly", "def=456;", "ghi=789"]

    assert_equal(
      {"abc" => "123", "def" => "456", "ghi" => "789"},
      @client.instance_variable_get("@cookies")
    )

    @client.cookies = ["abc=111; blah", "zzz=123"]

    assert_equal(
      {"abc" => "111", "def" => "456", "ghi" => "789", "zzz" => "123"},
      @client.instance_variable_get("@cookies")
    )
  end

  def test_cookies
    # Set an array instead of hash for predictable iteration and string construction
    @client.instance_variable_set("@cookies", [%w(abc 123), %w(def 456)])

    assert_equal "abc=123; def=456", @client.cookies
  end
end
