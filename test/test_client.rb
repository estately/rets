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
    @client.capabilities = { "foo" => "/foo" }

    assert_equal "http://example.com/foo", @client.capability_url("foo")
  end

  def test_capabilities_calls_login_when_nil
    @client.expects(:login)
    @client.capabilities
  end

  def test_tries_increments_with_each_call
    assert_equal 1, @client.tries
    assert_equal 2, @client.tries
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
    logger.fatal "foo"
    logger.error "foo"
    logger.warn  "foo"
    logger.info  "foo"
    logger.debug "foo"
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
    assert_raises Rets::AuthorizationFailure do
      @client.find(:all, :foo => :bar)
    end
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
    response.stubs(:headers => { "content-type" => ['text/plain']})
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

  def test_metadata_caches
    metadata = stub(:current? => true)
    @client.metadata = metadata
    @client.stubs(:capabilities => {})

    assert_same metadata, @client.metadata, "Should be memoized"
  end

  def test_decorate_result_handles_bad_metadata
    result = {'foo' => 'bar'}
    rets_class = stub
    rets_class.expects(:find_table).with('foo').returns(nil)
    response = @client.decorate_result(result, rets_class)
    assert_equal response, result
  end

end
