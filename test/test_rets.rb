require "test/unit"
require "mocha"

require "rets"

class TestRets < Test::Unit::TestCase

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
    client = Rets::Client.new(:login_url => "http://example.com")

    assert_kind_of Net::HTTP::Persistent, client.connection
  end

  def test_connection_uses_net_http
    client = Rets::Client.new(:login_url => "http://example.com", :persistent => false)

    assert_kind_of Net::HTTP, client.connection
    assert_equal "example.com", client.connection.address
    assert_equal 80, client.connection.port
  end


  def test_request_passes_correct_arguments_to_persistent_connection
    client = Rets::Client.new(:login_url => "http://example.com")

    client.connection.expects(:request).with(client.uri, instance_of(Net::HTTP::Post))
    client.request("/foo")
  end

  def test_request_passes_correct_arguments_to_net_http_connection
    client = Rets::Client.new(:login_url => "http://example.com", :persistent => false)

    client.connection.expects(:request).with(instance_of(Net::HTTP::Post))
    client.request("/foo")
  end
end
