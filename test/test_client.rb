require_relative "helper"

class TestClient < MiniTest::Test

  def setup
    @client = Rets::Client.new(:login_url => "http://example.com/login")
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
    client = Rets::Client.new(:login_url => "http://example.com", :capabilities => { "foo" => "/foo" })

    assert_equal "http://example.com/foo", client.capability_url("foo")
  end

  def test_cached_capabilities_case_insensitive
    client = Rets::Client.new(:login_url => "http://example.com", :capabilities => { "foo" => "/foo" })

    assert_equal client.capabilities.default_proc, Rets::Client::CASE_INSENSITIVE_PROC
  end

  def test_capabilities_calls_login_when_nil
    @client.expects(:login)
    @client.capabilities
  end

  def test_capabilities_does_not_call_login_after_login
    response = mock
    response.stubs(:body).returns(CAPABILITIES)
    @client.stubs(:http_get).returns(response)
    @client.login

    @client.expects(:login).never
    @client.capabilities
  end

  def test_tries_increments_with_each_call
    assert_equal 1, @client.tries
    assert_equal 2, @client.tries
  end

  def test_metadata_when_not_initialized_with_metadata
    new_raw_metadata = stub(:new_raw_metadata)

    client = Rets::Client.new(:login_url => "http://example.com")
    client.stubs(:retrieve_metadata).returns(new_raw_metadata)

    assert_same new_raw_metadata, client.metadata.marshal_dump
  end

  def test_initialize_with_old_metadata_cached_contstructs_new_metadata_from_request
    metadata = stub(:current? => false)
    new_raw_metadata = stub(:new_raw_metadata)

    client = Rets::Client.new(:login_url => "http://example.com", :metadata => metadata)
    client.stubs(:capabilities).returns({})
    client.stubs(:retrieve_metadata).returns(new_raw_metadata)

    assert_same new_raw_metadata, client.metadata.marshal_dump
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
    logger.fatal "foo"
    logger.error "foo"
    logger.warn  "foo"
    logger.info  "foo"
    logger.debug "foo"
  end

  def test_find_every_raises_on_missing_required_arguments
    assert_raises ArgumentError do
      @client.find_every({})
    end
    assert_raises ArgumentError do
      @client.find_every(:search_type => "Foo")
    end
    assert_raises ArgumentError do
      @client.find_every(:class => "Bar")
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
    assert_raises ArgumentError do
      @client.find(:incorrect, :foo => :bar)
    end
  end

  def test_response_text_encoding_from_ascii
    @client.stubs(:capability_url).with("Search").returns("search_url")
    response = mock
    response.stubs(:body).returns("An ascii string".encode("binary", "UTF-8"))

    assert_equal @client.clean_response(response).body, "An ascii string"
  end

  def test_response_text_encoding_from_utf_8
    @client.stubs(:capability_url).with("Search").returns("search_url")
    response = mock
    response.stubs(:body).returns("Some string with non-ascii characters \u0119")

    assert_equal @client.clean_response(response).body, "Some string with non-ascii characters \u0119"

  end

  def test_response_text_encoding_from_utf_16
    @client.stubs(:capability_url).with("Search").returns("search_url")
    response = mock
    response.stubs(:body).returns("Some string with non-utf-8 characters \xC2")

    assert_equal @client.clean_response(response).body, "Some string with non-utf-8 characters \uFFFD"
  end

  def test_find_retries_when_receiving_no_records_found
    @client.stubs(:find_every).raises(Rets::NoRecordsFound.new('')).then.returns([1])

    assert_equal [1], @client.find(:all)
  end

  def test_find_does_not_retry_when_receiving_no_records_found_with_option
    @client.stubs(:find_every).raises(Rets::NoRecordsFound.new(''))

    assert_equal [], @client.find(:all, no_records_not_an_error: true)
  end

  def test_find_does_not_retry_and_returns_zero_on_count_request_when_receiving_no_records_found_with_option
    @client.stubs(:find_every).raises(Rets::NoRecordsFound.new(''))

    assert_equal 0, @client.find(:all, count: 2, no_records_not_an_error: true)
  end

  def test_find_retries_on_errors
    @client.stubs(:find_every).raises(Rets::AuthorizationFailure.new(401, 'Not Authorized')).then.raises(Rets::InvalidRequest.new(20134, 'Not Found')).then.returns([])
    @client.stubs(:login)
    @client.find(:all, :foo => :bar)
  end

  def test_find_waits_configured_time_before_next_request
    @client.options[:recoverable_error_wait_secs] = 3.14
    @client.expects(:sleep).with(3.14).times(3)
    @client.stubs(:find_every).raises(Rets::MiscellaneousSearchError.new(0, 'Foo'))
    @client.find(:all, :foo => :bar) rescue nil
  end

  def test_find_eventually_reraises_errors
    @client.stubs(:find_every).raises(Rets::AuthorizationFailure.new(401, 'Not Authorized'))
    @client.stubs(:login)

    assert_raises Rets::AuthorizationFailure do
      @client.find(:all, :foo => :bar)
    end
  end

  def test_find_logs_in_after_auth_error
    @client.stubs(:find_every).raises(Rets::AuthorizationFailure.new(401, 'Not Authorized')).then.returns(["foo"])

    @client.expects(:login)
    @client.find(:all, :foo => :bar)
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
    @client.expects(:fetch_object).with("1:2:3", :foo => :bar)
    @client.stubs(:create_parts_from_response)

    @client.objects([1,2,3], :foo => :bar)
  end

  def test_objects_raises_on_other_arguments
    assert_raises ArgumentError do
      @client.objects(Object.new, :foo => :bar)
    end
  end

  def test_create_parts_from_response_returns_multiple_parts_when_multipart_response
    response = {}
    response.stubs(:header => { "content-type" => ['multipart; boundary="simple boundary"']})
    response.stubs(:body => MULITPART_RESPONSE)

    Rets::Parser::Multipart.expects(:parse).
      with(MULITPART_RESPONSE, "simple boundary").
      returns([])

    @client.create_parts_from_response(response)
  end

  def test_parse_boundary_wo_quotes
    response = {}
    response.stubs(:header => { "content-type" => ['multipart; boundary=simple boundary; foo;']})
    response.stubs(:body => MULITPART_RESPONSE)

    Rets::Parser::Multipart.expects(:parse).
      with(MULITPART_RESPONSE, "simple boundary").
      returns([])

    @client.create_parts_from_response(response)
  end

  def test_create_parts_from_response_returns_a_single_part_when_not_multipart_response
    response = {}
    response.stubs(:header => { "content-type" => ['text/plain']})
    response.stubs(:headers => { "Content-Type" => 'text/plain'})
    response.stubs(:body => "fakebody")

    parts = @client.create_parts_from_response(response)

    assert_equal 1, parts.size

    part = parts.first

    assert_equal "text/plain", part.headers["content-type"]
    assert_equal "fakebody", part.body
  end

  def test_object_calls_fetch_object
    response = stub(:body => "foo")

    @client.expects(:fetch_object).with("1", :foo => :bar).returns(response)

    assert_equal "foo", @client.object("1", :foo => :bar)
  end

  def test_decorate_result_handles_bad_metadata
    result = {'foo' => 'bar'}
    rets_class = stub
    rets_class.expects(:find_table).with('foo').returns(nil)
    response = @client.decorate_result(result, rets_class)
    assert_equal response, result
  end

  def test_clean_setup_with_receive_timeout
   HTTPClient.any_instance.expects(:receive_timeout=).with(1234)
   @client = Rets::Client.new(
       login_url: 'http://example.com/login',
       receive_timeout: 1234
   )
  end

  def test_clean_setup_with_proxy_auth
    @login_url = 'http://example.com/login'
    @proxy_url = 'http://example.com/proxy'
    @proxy_username = 'username'
    @proxy_password = 'password'
    HTTPClient.any_instance.expects(:set_proxy_auth).with(@proxy_username, @proxy_password)

    @client = Rets::Client.new(
        login_url: @login_url,
        http_proxy: @proxy_url,
        proxy_username: @proxy_username,
        proxy_password: @proxy_password
    )
  end

end
