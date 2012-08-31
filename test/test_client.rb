require "helper"

class TestClient < Test::Unit::TestCase

  def setup
    @client = Rets::Client.new(:login_url => "http://example.com/login")
  end

  def test_initialize_adds_escaped_username_to_uri
    client = Rets::Client.new(
      :login_url => "http://example.com",
      :username => "bob@example.com")

    assert_equal CGI.escape("bob@example.com"), client.login_uri.user
    assert_nil client.login_uri.password
  end

  def test_initialize_adds_escaped_password_to_uri
    client = Rets::Client.new(
      :login_url => "http://example.com",
      :username => "bob",
      :password => "secret@2!")

    assert_equal CGI.escape("secret@2!"), client.login_uri.password
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

    headers = @client.build_headers('path')

    Net::HTTP::Post.expects(:new).with("/foo", headers).returns(post)

    @client.connection.expects(:request).with(@client.login_uri, post).returns(stub_everything)

    @client.expects(:handle_cookies)
    @client.expects(:handle_response)

    @client.stubs(:format_headers)

    @client.request("/foo", "fake body")
  end

  def test_request_with_block
    # TODO
  end

  def test_request_passes_correct_arguments_to_persistent_connection
    @client.connection.expects(:request).with(@client.login_uri, instance_of(Net::HTTP::Post)).returns(stub_everything)

    @client.stubs(:handle_cookies)
    @client.stubs(:handle_response)
    @client.stubs(:format_headers)

    @client.request("/foo")
  end

  def test_request_passes_correct_arguments_to_net_http_connection
    client = Rets::Client.new(:login_url => "http://example.com", :persistent => false)

    client.connection.expects(:request).with(instance_of(Net::HTTP::Post)).returns(stub_everything)

    client.stubs(:handle_cookies)
    client.stubs(:handle_response)
    client.stubs(:format_headers)

    client.request("/foo")
  end

  def test_handle_response_handles_rets_errors
    response = Net::HTTPSuccess.new("", "", "")
    response.stubs(:body => RETS_ERROR)

    assert_raise Rets::InvalidRequest do
      @client.handle_response(response)
    end
  end

  def test_handle_response_handles_rets_valid_response
    response = Net::HTTPSuccess.new("", "", "")
    response.stubs(:body => RETS_REPLY)

    assert_equal response, @client.handle_response(response)
  end

  def test_handle_response_handles_empty_responses
    response = Net::HTTPSuccess.new("", "", "")
    response.stubs(:body => "")

    assert_equal response, @client.handle_response(response)
  end

  def test_handle_response_handles_non_xml_responses
    response = Net::HTTPSuccess.new("", "", "")
    response.stubs(:body => "<notxml")

    assert_equal response, @client.handle_response(response)
  end

  def test_handle_response_raises_on_unknown_response_code
    response = Net::HTTPServerError.new("", "", "")

    assert_raise Rets::UnknownResponse do
      assert_equal response, @client.handle_response(response)
    end
  end

  def test_extract_capabilities
    assert_equal(
      {"abc" => "123", "def" => "ghi=jk"},
      @client.extract_capabilities(Nokogiri.parse(CAPABILITIES))
    )
  end

  def test_extract_capabilities_with_whitespace
    assert_equal(
      {"action" => "/RETS/Action"},
      @client.extract_capabilities(Nokogiri.parse(CAPABILITIES_WITH_WHITESPACE))
    )
  end

  def test_capability_url_returns_parsed_url
    @client.capabilities = { "foo" => "http://example.com" }

    assert_equal URI.parse("http://example.com"), @client.capability_url("foo")
  end

  def test_capability_url_raises_on_malformed_url
    @client.capabilities = { "foo" => "http://e$^&#$&xample.com" }

    assert_raise Rets::MalformedResponse do
      @client.capability_url("foo")
    end
  end

  def test_capabilities_calls_login_when_nil
    @client.expects(:login)
    @client.capabilities
  end

  def test_login_fails_if_cannot_read_capabilities
    response = Net::HTTPSuccess.new("", "", "")
    response.stubs(:body => RETS_REPLY)
    @client.stubs(:request).returns(response)
    @client.stubs(:extract_capabilities)
    assert_raise Rets::UnknownResponse do
      @client.login
    end
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


  def test_build_headers_provides_basic_headers
    assert_equal({
      "User-Agent"    => "Client/1.0",
      "Host"          => "example.com:80",
      "RETS-Version"  => "RETS/1.7.2"},
      @client.build_headers('path'))
  end

  def test_build_headers_provides_authorization
    @client.expects(:authorization).returns("Just trust me")

    assert_equal({
      "Authorization" => "Just trust me",
      "User-Agent"    => "Client/1.0",
      "Host"          => "example.com:80",
      "RETS-Version"  => "RETS/1.7.2"},
      @client.build_headers('path'))
  end

  def test_build_headers_provides_cookies
    @client.cookies = ["Allowed=totally"]

    assert_equal({
      "Cookie"        => "Allowed=totally",
      "User-Agent"    => "Client/1.0",
      "Host"          => "example.com:80",
      "RETS-Version"  => "RETS/1.7.2"},
      @client.build_headers('path'))
  end


  def test_tries_increments_with_each_call
    assert_equal 1, @client.tries
    assert_equal 2, @client.tries
  end

  def test_build_auth
    www_authenticate =
      %q(Digest realm="EXAMPLE", nonce="aec306b318feef4c360bc986e06d0a71", opaque="4211001cd29d5a65b3ed99f766a896b0", qop="auth")

    uri = URI.parse("http://bob:secret@example.com/login")

    Digest::MD5.stubs(:hexdigest => "heeheehee")

    expected = <<-DIGEST.gsub(/\n/, "")
Digest username="bob", realm="EXAMPLE", qop="auth", uri="/login", nonce="aec306b318feef4c360bc986e06d0a71", 
nc=00000000, cnonce="heeheehee", response="heeheehee", opaque="4211001cd29d5a65b3ed99f766a896b0"
DIGEST

    assert_equal expected, @client.build_auth(www_authenticate, uri)
  end

  def test_calculate_digest_with_qop
    Digest::MD5.expects(:hexdigest).with("bob:example:secret").returns("a1")
    Digest::MD5.expects(:hexdigest).with("POST:/login").returns("a2")

    Digest::MD5.expects(:hexdigest).with("a1:nonce:00000001:cnonce:qop:a2")

    @client.calculate_digest("bob", "secret", "example", "nonce", "POST", URI.parse("/login"), "qop", "cnonce", 1)
  end

  def test_calculate_digest_without_qop
    Digest::MD5.expects(:hexdigest).with("bob:example:secret").returns("a1")
    Digest::MD5.expects(:hexdigest).with("POST:/login").returns("a2")

    Digest::MD5.expects(:hexdigest).with("a1:nonce:a2").returns("hash")

    assert_equal "hash",
      @client.calculate_digest("bob", "secret", "example", "nonce", "POST", URI.parse("/login"), nil, "cnonce", 1)
  end

  def test_calculate_user_agent_digest
    Digest::MD5.expects(:hexdigest).with("agent:secret").returns("a1")
    Digest::MD5.expects(:hexdigest).with("a1::session:version").returns("hash")

    assert_equal "hash",
      @client.calculate_user_agent_digest("agent", "secret", '', "session", "version")
  end


  def test_session_restores_state
    session = Rets::Session.new({:digest => 'true'}, {"Foo" => "/foo"}, "sessionid=123")

    @client.session = session

    assert_equal({:digest => 'true'},     @client.auth_digest)
    assert_equal({"Foo" => "/foo"}, @client.capabilities)
    assert_equal("sessionid=123",   @client.cookies)
  end

  def test_session_dumps_state
    @client.auth_digest = {:digest => 'true'}
    @client.capabilities  = {"Foo" => "/foo"}
    @client.cookies       = "session-id=123"

    session = @client.session

    assert_equal({:digest => 'true'},     session.auth_digest)
    assert_equal({"Foo" => "/foo"}, session.capabilities)
    assert_equal("session-id=123",  session.cookies)
  end

  def test_initialize_with_session_restores_state
    session = Rets::Session.new({:digest => true}, {"Foo" => "/foo"}, "sessionid=123")

    client = Rets::Client.new(:login_url => "http://example.com", :session => session)

    assert_equal({:digest => true},     client.auth_digest)
    assert_equal({"Foo" => "/foo"}, client.capabilities)
    assert_equal("sessionid=123",   client.cookies)
  end

  def test_metadata_when_not_initialized_with_metadata
    client = Rets::Client.new(:login_url => "http://example.com")
    Rets::Metadata::Root.expects(:new)
    client.metadata
  end

  def test_initialize_with_old_metadata_cached_gets_new_metadata
    metadata = stub(:current? => false)
    new_metadata = stub(:current? => false)
    client = Rets::Client.new(:login_url => "http://example.com", :metadata => metadata)
    client.stubs(:capabilities => {})
    Rets::Metadata::Root.expects(:new => new_metadata).once

    assert_same new_metadata, client.metadata
    # This second call ensures the expectations on Root are met
    client.metadata
  end

  def test_initialize_with_current_metadata_cached_return_cached_metadata
    metadata = stub(:current? => true)
    client = Rets::Client.new(:login_url => "http://example.com", :metadata => metadata)
    client.stubs(:capabilities => {})

    assert_same metadata, client.metadata
  end

  def test_initialize_takes_logger
    logger = Object.new

    client = Rets::Client.new(:login_url => "http://example.com", :logger => logger)

    assert_equal logger, client.logger
  end

  def test_default_logger_returns_api_compatible_silent_logger
    logger = @client.logger

    assert_nothing_raised do
      logger.fatal "foo"
      logger.error "foo"
      logger.warn  "foo"
      logger.info  "foo"
      logger.debug "foo"
    end
  end


  def test_find_first_calls_find_every_with_limit_one
    @client.expects(:find_every).with({:limit => 1, :foo => :bar}, nil).returns([1,2,3])

    assert_equal 1, @client.find(:first, :foo => :bar, :limit => 5), "User-specified limit should be ignored"
  end

  def test_find_all_calls_find_every
    @client.expects(:find_every).with({:limit => 5, :foo => :bar}, nil).returns([1,2,3])

    assert_equal [1,2,3], @client.find(:all, :limit => 5, :foo => :bar)
  end

  def test_find_raises_on_unknown_quantity
    assert_raise ArgumentError do
      @client.find(:incorrect, :foo => :bar)
    end
  end

  def test_find_retries_on_errors
    @client.stubs(:find_every).raises(Rets::AuthorizationFailure).then.raises(Rets::InvalidRequest).then.returns([])
    @client.find(:all, :foo => :bar)
  end

  def test_find_retries_on_errors_preserves_resolve
    @client.stubs(:find_every).raises(Rets::AuthorizationFailure).then.raises(Rets::InvalidRequest).then.with({:foo => :bar}, true).returns([])
    @client.find(:all, {:foo => :bar, :resolve => true})
  end

  def test_find_eventually_reraises_errors
    @client.stubs(:find_every).raises(Rets::AuthorizationFailure)
    assert_raise Rets::AuthorizationFailure do
      @client.find(:all, :foo => :bar)
    end
  end

  def test_find_provides_default_values
    @client.expects(:build_key_values).
      with("QueryType" => "DMQL2", "Format" => "COMPACT", "Query" => "x", "Foo" => "bar").
      returns("xxx")

    @client.stubs(:capability_url => URI.parse("/example"))
    @client.stubs(:request_with_compact_response)

    @client.find(:all, :query => "x", :foo => "bar")
  end

  def test_find_allows_defaults_to_be_overridden
    @client.expects(:build_key_values).
      with("QueryType" => "DMQL3000", "Format" => "COMPACT", "Query" => "x", "Foo" => "bar").
      returns("xxx")

    @client.stubs(:capability_url => URI.parse("/example"))
    @client.stubs(:request_with_compact_response)

    @client.find(:all, :query => "x", :foo => "bar", :query_type => "DMQL3000")
  end

  def test_find_returns_undecorated_results
    @client.stubs(:capability_url => URI.parse("/example"))

    @client.expects(:request_with_compact_response).
      with("/example", instance_of(String), instance_of(Hash)).
      returns([["foo", "bar"]])

    results = @client.find(:all, :search_type => "Property", :class => "Res", :query => "x", :foo => "bar")

    assert_equal [["foo", "bar"]], results
  end

  def test_find_returns_decorated_results
    @client.stubs(:capability_url => URI.parse("/example"))

    @client.expects(:request_with_compact_response).
      with("/example", instance_of(String), instance_of(Hash)).
      returns([["foo", "bar"]])

    fake_rets_class = stub(:rets_class)
    fake_result = stub(:result)

    @client.expects(:find_rets_class).with("Property", "Res").returns(fake_rets_class)
    @client.expects(:decorate_results).with([["foo", "bar"]], fake_rets_class).returns(fake_result)

    results = @client.find(:all, :search_type => "Property", :class => "Res", :query => "x", :foo => "bar", :resolve => true)

    assert_equal fake_result, results
  end

  def test_fixup_keys
    assert_equal({ "Foo" => "bar" },    @client.fixup_keys(:foo => "bar"))
    assert_equal({ "FooFoo" => "bar" }, @client.fixup_keys(:foo_foo => "bar"))
  end

  def test_all_objects_calls_objects
    @client.expects(:objects).with("*", :foo => :bar)

    @client.all_objects(:foo => :bar)
  end

  def test_objects_handles_string_argument
    @client.expects(:fetch_object).with("*", :foo => :bar)
    @client.stubs(:create_parts_from_response)

    @client.objects("*", :foo => :bar)
  end

  def test_objects_handle_array_argument
    @client.expects(:fetch_object).with("1,2", :foo => :bar)
    @client.stubs(:create_parts_from_response)

    @client.objects([1,2], :foo => :bar)
  end

  def test_unauthorized_session
    session = Rets::Session.new(
      "Digest username=\"login\", realm=\"fake_realm\", qop=\"auth\", uri=\"/Login.asmx/Login\", nonce=\"a8f4bc805062602c8ba7a87b2109f808\", nc=00000001, cnonce=\"6e2dd038eea6cbacf0b956fd11f914b6\", response=\"fake_digest\", opaque=\"96eda461-41d0-4624-b7fe-b59e966035f3\"",
      {
        "GetObject"=>"/GetObject.asmx/GetObject",
        "GetMetadata"=>"/GetMetadata.asmx/GetMetadata",
        "Login"=>"/Login.asmx/Login",
        "metadatatimestamp"=>"2012-07-17T16:34:22Z",
        "user"=>"23756,60,RH,login",
        "Search"=>"/Search.asmx/Search",
        "timeoutseconds"=>"7200"
      },
      "ASP.NET_SessionId=mapij045k3bphj3gqqgpmmrx; RETS-Session-ID=mapij045k3bphj3gqqgpmmrx"
    )
    opts = {
      :username  => 'login',
      :password  => 'Bn1X@y4L',
      :login_url => 'http://rets.example.com/Login.asmx/Login',
      :agent     => 'Estately/1.0',
      :persistent => false,
      :session    => session
    }
    client = Rets::Client.new(opts)
    response = nil
    VCR.use_cassette('unauthorized_response') do
      response = client.objects("1",
                                :resource    => 'Property',
                                :object_type => 'Photo',
                                :resource_id => '2661580'
                               )
    end
    assert_equal 'image/jpeg', response.first.headers['content-type']
  end


  def test_objects_raises_on_other_arguments
    assert_raise ArgumentError do
      @client.objects(Object.new, :foo => :bar)
    end
  end

  def test_create_parts_from_response_returns_multiple_parts_when_multipart_response
    response = {"content-type" => 'multipart; boundary="simple boundary"'}
    response.stubs(:body => MULITPART_RESPONSE)

    Rets::Parser::Multipart.expects(:parse).
      with(MULITPART_RESPONSE, "simple boundary").
      returns([])

    @client.create_parts_from_response(response)
  end

  def test_parse_boundary_wo_quotes
    response = {"content-type" => 'multipart; boundary=simple boundary; foo;'}
    response.stubs(:body => MULITPART_RESPONSE)

    Rets::Parser::Multipart.expects(:parse).
      with(MULITPART_RESPONSE, "simple boundary").
      returns([])

    @client.create_parts_from_response(response)
  end

  def test_create_parts_from_response_returns_a_single_part_when_not_multipart_response
    response = {"content-type" => "text/plain"}
    response.stubs(:body => "fakebody")

    parts = @client.create_parts_from_response(response)

    assert_equal 1, parts.size

    part = parts.first

    assert_equal response,   part.headers
    assert_equal "fakebody", part.body
  end

  def test_object_calls_fetch_object
    response = stub(:body => "foo")

    @client.expects(:fetch_object).with("1", :foo => :bar).returns(response)

    assert_equal "foo", @client.object("1", :foo => :bar)
  end

  def test_fetch_object
    @client.expects(:capability_url).with("GetObject").returns(URI.parse("/obj"))

    @client.expects(:build_key_values => "fakebody").with(
      "Resource" => "Property",
      "Type"     => "Image",
      "ID"       => "123:*",
      "Location" => 0
    )

    @client.expects(:request).with("/obj", "fakebody",
      has_entries(
        "Accept"         => "image/jpeg, image/png;q=0.5, image/gif;q=0.1",
        "Content-Type"   => "application/x-www-form-urlencoded",
        "Content-Length" => "8")
      )

    @client.fetch_object("*", :resource => "Property", :object_type => "Image", :resource_id => "123")
  end

  def test_metadata_caches
    metadata = stub(:current? => true)
    @client.metadata = metadata
    @client.stubs(:capabilities => {})

    assert_same metadata, @client.metadata, "Should be memoized"
  end

  def test_retrieve_metadata_type
    @client.expects(:capability_url).with("GetMetadata").returns(URI.parse("/meta"))

    @client.expects(:build_key_values => "fakebody").with(
      "Format" => "COMPACT",
      "Type"   => "METADATA-FOO",
      "ID"     => "0"
    )

    @client.expects(:request => stub(:body => "response")).with("/meta", "fakebody", has_entries(
      "Content-Type"   => "application/x-www-form-urlencoded",
      "Content-Length" => "8"
    ))

    assert_equal "response", @client.retrieve_metadata_type("FOO")
  end

  def test_decorate_result_handles_bad_metadata
    result = {'foo' => 'bar'}
    rets_class = stub
    rets_class.expects(:find_table).with('foo').returns(nil)
    response = @client.decorate_result(result, rets_class)
    assert_equal response, result
  end

end
