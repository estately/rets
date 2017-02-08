require "minitest"
require "mocha/setup"

require_relative "../lib/rets"

require_relative "fixtures"

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr_cassettes'
  c.hook_into :webmock
end

class MockHttpClient
  attr_reader :stubbed_urls

  def initialize(stubbed_urls)
    @stubbed_urls = stubbed_urls
  end

  def http_post(url, params, extra_headers)
    Response.new(stubbed_urls.fetch(url))
  end

  def http_get(url, params, extra_headers)
    Response.new(stubbed_urls.fetch(url))
  end

  class Response
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end
end
