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

    headers = @client.build_headers

    Net::HTTP::Post.expects(:new).with("/foo", headers).returns(post)

    @client.connection.expects(:request).with(@client.uri, post).returns(stub(:body))

    @client.expects(:handle_cookies)
    @client.expects(:handle_response)

    @client.request("/foo", "fake body")
  end

  def test_request_with_block
    # TODO
  end

  def test_request_passes_correct_arguments_to_persistent_connection
    @client.connection.expects(:request).with(@client.uri, instance_of(Net::HTTP::Post)).returns(stub(:body))

    @client.stubs(:handle_cookies)
    @client.stubs(:handle_response)

    @client.request("/foo")
  end

  def test_request_passes_correct_arguments_to_net_http_connection
    client = Rets::Client.new(:login_url => "http://example.com", :persistent => false)

    client.connection.expects(:request).with(instance_of(Net::HTTP::Post)).returns(stub(:body))

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

    assert_raise Rets::AuthorizationFailure do
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

    assert_raise Rets::MalformedResponse do
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


  def test_build_headers_provides_basic_headers
    assert_equal({
      "User-Agent"    => "Client/1.0",
      "Host"          => "example.com:80",
      "RETS-Version"  => "RETS/1.7.2"},
      @client.build_headers)
  end

  def test_build_headers_provides_authorization
    @client.authorization = "Just trust me"

    assert_equal({
      "Authorization" => "Just trust me",
      "User-Agent"    => "Client/1.0",
      "Host"          => "example.com:80",
      "RETS-Version"  => "RETS/1.7.2"},
      @client.build_headers)
  end

  def test_build_headers_provides_cookies
    @client.cookies = ["Allowed=totally"]

    assert_equal({
      "Cookie"        => "Allowed=totally",
      "User-Agent"    => "Client/1.0",
      "Host"          => "example.com:80",
      "RETS-Version"  => "RETS/1.7.2"},
      @client.build_headers)
  end


  def test_tries_increments_with_each_call
    assert_equal 0, @client.tries
    assert_equal 1, @client.tries
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
      @client.calculate_user_agent_digest("agent", "secret", "session", "version")
  end


  def test_session_restores_state
    session = Rets::Session.new("Digest auth", {"Foo" => "/foo"}, "sessionid=123")

    @client.session = session

    assert_equal("Digest auth",     @client.authorization)
    assert_equal({"Foo" => "/foo"}, @client.capabilities)
    assert_equal("sessionid=123",   @client.cookies)
  end

  def test_session_dumps_state
    @client.authorization = "Digest auth"
    @client.capabilities  = {"Foo" => "/foo"}
    @client.cookies       = "session-id=123"

    session = @client.session

    assert_equal("Digest auth",     session.authorization)
    assert_equal({"Foo" => "/foo"}, session.capabilities)
    assert_equal("session-id=123",  session.cookies)
  end

  def test_initialize_with_session_restores_state
    session = Rets::Session.new("Digest auth", {"Foo" => "/foo"}, "sessionid=123")

    client = Rets::Client.new(:login_url => "http://example.com", :session => session)

    assert_equal("Digest auth",     client.authorization)
    assert_equal({"Foo" => "/foo"}, client.capabilities)
    assert_equal("sessionid=123",   client.cookies)
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
    @client.expects(:find_every).with(:limit => 1, :foo => :bar).returns([1,2,3])

    assert_equal 1, @client.find(:first, :foo => :bar, :limit => 5), "User-specified limit should be ignored"
  end

  def test_find_all_calls_find_every
    @client.expects(:find_every).with(:limit => 5, :foo => :bar).returns([1,2,3])

    assert_equal [1,2,3], @client.find(:all, :limit => 5, :foo => :bar)
  end

  def test_find_raises_on_unknown_quantity
    assert_raise ArgumentError do
      @client.find(:incorrect, :foo => :bar)
    end
  end

  def test_find_provides_default_values
    @client.expects(:build_key_values).
      with("QueryType" => "DMQL2", "Format" => "COMPACT", "Query" => "x", "Foo" => "bar").
      returns("xxx")

    @client.stubs(:capability => URI.parse("/example"))
    @client.stubs(:request_with_compact_response)

    @client.find(:all, :query => "x", :foo => "bar")
  end

  def test_find_allows_defaults_to_be_overridden
    @client.expects(:build_key_values).
      with("QueryType" => "DMQL3000", "Format" => "COMPACT", "Query" => "x", "Foo" => "bar").
      returns("xxx")

    @client.stubs(:capability => URI.parse("/example"))
    @client.stubs(:request_with_compact_response)

    @client.find(:all, :query => "x", :foo => "bar", :query_type => "DMQL3000")
  end

  def test_find
    @client.stubs(:capability => URI.parse("/example"))

    @client.expects(:request_with_compact_response).
      with("/example", instance_of(String), instance_of(Hash)).
      returns([["foo", "bar"]])

    results = @client.find(:all, :resource => "Property", :class => "Res", :query => "x", :foo => "bar")

    assert_equal [["foo", "bar"]], results
  end

  def test_fixup_keys
    assert_equal({ "Foo" => "bar" },    @client.fixup_keys(:foo => "bar"))
    assert_equal({ "FooFoo" => "bar" }, @client.fixup_keys(:foo_foo => "bar"))
  end

  # Compact Parser

  def test_parse_document_raises_on_invalid_delimiter
    assert_raise Rets::Parser::Compact::InvalidDelimiter do
      Rets::Parser::Compact.parse_document(INVALID_DELIMETER)
    end
  end

  def test_parse_document_uses_default_delimiter_when_none_provided
    #  we assert that the delimeter character getting to parse is a tab
    #  even though COMPACT defines no delimiter tag
    Rets::Parser::Compact.expects(:parse).with("A\tB", "1\t2", "\t")
    Rets::Parser::Compact.expects(:parse).with("A\tB", "4\t5", "\t")
    Rets::Parser::Compact.parse_document(COMPACT)
  end

  def test_parse_document_delegates_to_parse
    result = Rets::Parser::Compact.parse_document(COMPACT)

    assert_equal [[%w(A 1), %w(B 2)], [%w(A 4), %w(B 5)]], result
  end

  def test_parser_ignores_leading_tabs
    result = Rets::Parser::Compact.parse_document(METADATA_OBJECT)

    result.each do |row|
      assert !row.any? { |k,v| k.to_s.size == 0 }, "Should not contain empty keys"
    end
  end

  def test_parse_returns_key_value_pairs
    result = Rets::Parser::Compact.parse("A\tB", "1\t2")

    assert_equal [%w(A 1), %w(B 2)], result
  end

  # Metadata module

  def test_metadata_build_uses_row_containers_for_resource
    doc = Nokogiri.parse(METADATA_RESOURCE)

    resource_container = Rets::Metadata.build(doc)

    assert_instance_of Rets::Metadata::ResourceContainer, resource_container

    assert_equal 13, resource_container.size

    resource = resource_container.first

    assert_equal "ActiveAgent", resource["StandardName"]
  end

  def test_metadata_build_uses_system_container_for_system
    doc = Nokogiri.parse(METADATA_SYSTEM)

    system_container = Rets::Metadata.build(doc)

    assert_instance_of Rets::Metadata::SystemContainer, system_container

    assert_equal doc, system_container.doc
  end

  def test_metadata_build_uses_base_container_for_unknown_metadata_types
    doc = Nokogiri.parse(METADATA_UNKNOWN)

    unknown_container = Rets::Metadata.build(doc)

    assert_instance_of Rets::Metadata::Container, unknown_container

    assert_equal doc, unknown_container.doc
  end

  # Metadata on Client

  def test_metadata_returns_hash_of_metadata_types
    Rets::METADATA_TYPES.each do |type|
      @client.expects(:metadata_type).with(type)
    end

    Rets::Metadata.stubs(:build)

    expected_keys = Rets::METADATA_TYPES.map { |t| t.downcase.to_sym }.sort_by(&:to_s)

    assert_equal expected_keys, @client.metadata.keys.sort_by(&:to_s)
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

# 44 is the ASCII code for comma; an invalid delimiter.
INVALID_DELIMETER = <<-XML
<?xml version="1.0"?>
<METADATA-RESOURCE Version="01.72.10306" Date="2011-03-15T19:51:22">
  <DELIMITER value="44" />
  <COLUMNS>A\tB</COLUMNS>
  <DATA>1\t2</DATA>
  <DATA>4\t5</DATA>
</METADATA>
XML

COMPACT = <<-XML
<?xml version="1.0"?>
<METADATA-RESOURCE Version="01.72.10306" Date="2011-03-15T19:51:22">
  <COLUMNS>A\tB</COLUMNS>
  <DATA>1\t2</DATA>
  <DATA>4\t5</DATA>
</METADATA>
XML

METADATA_UNKNOWN = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="Operation successful.">
<METADATA-FOO Version="01.72.10306" Date="2011-03-15T19:51:22">
<UNKNOWN />
</METADATA-FOO>
XML

METADATA_SYSTEM = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="Operation successful.">
<METADATA-SYSTEM Version="01.72.10306" Date="2011-03-15T19:51:22">
<SYSTEM />
<COMMENTS />
</METADATA-SYSTEM>
XML

METADATA_RESOURCE = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="Operation successful.">
<METADATA-RESOURCE Version="01.72.10306" Date="2011-03-15T19:51:22">
<COLUMNS>	ResourceID	StandardName	VisibleName	Description	KeyField	ClassCount	ClassVersion	ClassDate	ObjectVersion	ObjectDate	SearchHelpVersion	SearchHelpDate	EditMaskVersion	EditMaskDate	LookupVersion	LookupDate	UpdateHelpVersion	UpdateHelpDate	ValidationExpressionVersion	ValidationExpressionDate	ValidationLookupVersionValidationLookupDate	ValidationExternalVersion	ValidationExternalDate	</COLUMNS>
<DATA>	ActiveAgent	ActiveAgent	Active Agent Search	Contains information about active agents.	MemberNumber	1	01.72.10304	2011-03-03T00:29:23	01.72.10000	2010-08-16T15:08:20	01.72.10305	2011-03-09T21:33:41			01.72.10284	2011-02-24T06:56:43		</DATA>
<DATA>	Agent	Agent	Agent Search	Contains information about all agents.	MemberNumber	1	01.72.10303	2011-03-03T00:29:23	01.72.10000	2010-08-16T15:08:20	01.72.10305	2011-03-09T21:33:41			01.72.10284	2011-02-24T06:56:43						</DATA>
<DATA>	History	History	History Search	Contains information about accumulated changes to each listing.	TransactionRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10000	2010-08-16T22:08:30			01.72.10000	2010-08-16T15:08:20			</DATA>
<DATA>	MemberAssociation		Member Association	Contains MLS member Association information.	MemberAssociationKey	1	01.72.10277	2011-02-23T19:11:10			01.72.10214	2011-01-06T16:41:05	01.72.10220	2011-01-06T16:41:06						</DATA>
<DATA>	Office	Office	Office Search	Contains information about broker offices.	OfficeNumber	1	01.72.10302	2011-03-03T00:29:23	01.72.10000	2010-08-16T15:08:20	01.72.10305	2011-03-09T21:33:41		01.72.10284	2011-02-24T06:56:43						</DATA>
<DATA>	OfficeAssociation		Office Association	Contains MLS office Association information.	OfficeAssociationKey	1	01.72.10306	2011-03-15T19:51:22			01.72.10245	2011-01-06T16:41:08	01.72.10251	2011-01-06T16:41:08						</DATA>
<DATA>	OpenHouse	OpenHouse	Open House Search	Contains information about public open house activities.	OpenHouseRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10134	2010-11-12T13:57:32			01.72.10000	2010-08-16T15:08:20									</DATA>
<DATA>	Property	Property	Property Search	Contains information about listed properties.	ListingRid	8	01.72.10288	2011-02-24T06:59:11	01.72.10000	2010-08-16T15:08:20	01.72.10289	2011-02-24T06:59:19			01.72.10290	2011-03-01T11:06:31			</DATA>
<DATA>	PropertyDeleted		Deleted Property Search	Contains information about deleted properties.	ListingRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10000	2010-08-16T22:08:30			01.72.10000	2010-08-16T22:08:34			</DATA>
<DATA>	PropertyWithheld		Withheld Property Search	Contains information about withheld properties.	ListingRid	8	01.72.10201	2011-01-05T19:34:36	01.72.10000	2010-08-16T15:08:20	01.72.10200	2011-01-05T19:34:34			01.72.10000	2010-08-16T22:08:34	</DATA>
<DATA>	Prospect	Prospect	Prospect Search	Contains information about sales or listing propects.	ProspectRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10000	2010-08-16T15:08:20			01.72.10000	2010-08-16T15:08:20		</DATA>
<DATA>	Tour	Tour	Tour Search	Contains information about private tour activities.	TourRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10000	2010-08-16T22:08:30		01.72.10000	2010-08-16T15:08:20						</DATA>
<DATA>	VirtualMedia		Virtual Media	Contains information about virtual media for MLS listings.	VirtualMediaRid	1	01.72.10126	2010-11-12T13:47:41			01.72.10127	2010-11-12T13:47:41		01.72.10086	2010-11-10T09:59:11						</DATA>
</METADATA-RESOURCE>
</RETS>
XML

METADATA_OBJECT = "<RETS ReplyCode=\"0\" ReplyText=\"V2.6.0 728: Success\">\r\n<METADATA-OBJECT Resource=\"Property\" Version=\"1.12.24\" Date=\"Wed, 1 Dec 2010 00:00:00 GMT\">\r\n<COLUMNS>\tMetadataEntryID\tObjectType\tStandardName\tMimeType\tVisibleName\tDescription\tObjectTimeStamp\tObjectCount\t</COLUMNS>\r\n<DATA>\t50045650619\tMedium\tMedium\timage/jpeg\tMedium\tA 320 x 240 Size Photo\tLastPhotoDate\tTotalPhotoCount\t</DATA>\r\n<DATA>\t20101753230\tDocumentPDF\tDocumentPDF\tapplication/pdf\tDocumentPDF\tDocumentPDF\t\t\t</DATA>\r\n<DATA>\t50045650620\tPhoto\tPhoto\timage/jpeg\tPhoto\tA 640 x 480 Size Photo\tLastPhotoDate\tTotalPhotoCount\t</DATA>\r\n<DATA>\t50045650621\tThumbnail\tThumbnail\timage/jpeg\tThumbnail\tA 128 x 96 Size Photo\tLastPhotoDate\tTotalPhotoCount\t</DATA>\r\n</METADATA-OBJECT>\r\n</RETS>\r\n"
