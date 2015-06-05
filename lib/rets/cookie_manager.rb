require 'httpclient'
require 'http-cookie'

module Rets
  class CookieManager < WebAgent::CookieManager
    attr_reader :jar

    def initialize(cookies_file = nil, format = HTTPClient::WebAgentSaver, jar = HTTP::CookieJar.new)
      super(cookies_file, format)
      @jar = jar
      load_cookies if @cookies_file
    end
  end
end
