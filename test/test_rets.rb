require "test/unit"
require "mocha"

require "rets"

class TestRets < Test::Unit::TestCase

  def setup
    @client = Rets::Client.new(:login_url => "http://example.com/login")
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

  def test_initialize_allows_default_options_to_be_overridden
    assert Rets::Client::DEFAULT_OPTIONS.include?(:persistent)

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


  def test_handle_response_instigates_login_process
    response = Net::HTTPUnauthorized.new("","","")

    @client.expects(:handle_unauthorized_response)

    assert_equal response, @client.handle_response(response)
  end

  def test_handle_response_handles_rets_errors
    response = stub(:body => RETS_ERROR)

    assert_raise(Rets::InvalidRequest) do
      @client.handle_response(response)
    end
  end

  def test_handle_response_handles_rets_valid_response
    response = stub(:body => RETS_REPLY)

    assert_equal response, @client.handle_response(response)
  end

  def test_handle_response_handles_empty_responses
    response = stub(:body => "")

    assert_equal response, @client.handle_response(response)
  end

  def test_handle_response_handles_non_xml_responses
    response = stub(:body => "<notxml")

    assert_equal response, @client.handle_response(response)
  end


  def test_handle_unauthorized_response_sets_capabilities_on_success
    response = Net::HTTPSuccess.new("","","")
    response.stubs(:body => CAPABILITIES)

    @client.stubs(:build_auth)
    @client.expects(:raw_request).with("/login").returns(response)

    @client.handle_unauthorized_response({'www-authenticate' => 'xxx'})

    capabilities = {"Abc" => "123", "Def" => "ghi=jk"}

    assert_equal capabilities, @client.capabilities
  end

  def test_handle_unauthorized_response_raises_on_auth_failure
    response = Net::HTTPUnauthorized.new("","","")
    response.stubs(:body => "")

    @client.stubs(:build_auth)
    @client.expects(:raw_request).with("/login").returns(response)

    assert_raises(Rets::AuthorizationFailure) do
      @client.handle_unauthorized_response({'www-authenticate' => 'xxx'})
    end
  end



  def test_extract_capabilities
    assert_equal(
      {"Abc" => "123", "Def" => "ghi=jk"},
      @client.extract_capabilities(Nokogiri.parse(CAPABILITIES))
    )
  end

  def test_capability_returns_parsed_url
    @client.capabilities = { "Foo" => "http://example.com" }

    assert_equal URI.parse("http://example.com"), @client.capability("Foo")
  end

  def test_capability_raises_on_malformed_url
    @client.capabilities = { "Foo" => "http://e$^&#$&xample.com" }

    assert_raises(Rets::MalformedResponse) do
      @client.capability("Foo")
    end
  end

  def test_capabilities_calls_login_when_nil
    @client.expects(:login)
    @client.capabilities
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

RETS_ERROR = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="123" ReplyText="Error message">
</RETS>
XML

RETS_REPLY = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="OK">
</RETS>
XML

CAPABILITIES = <<-XML
<RETS ReplyCode="0" ReplyText="OK">
  <RETS-RESPONSE>

    Abc=123
    Def=ghi=jk

  </RETS-RESPONSE>
</RETS>
XML
