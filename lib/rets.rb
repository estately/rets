require 'net/http'
require 'uri'
require 'cgi'
require 'digest/md5'

require 'rubygems'
require 'net/http/persistent'

module Rets
  VERSION = '0.0.1'

  class Client

    DEFAULT_OPTIONS = { :persistent => true }

    attr_accessor :uri, :options

    def initialize(options)
      uri          = URI.parse(options[:login_url])

      uri.user     = options.key?(:username) ? CGI.escape(options[:username]) : nil
      uri.password = options.key?(:password) ? CGI.escape(options[:password]) : nil

      self.options = DEFAULT_OPTIONS.merge(options)
      self.uri     = uri
    end


    # Attempts to login by making an empty request to the URL
    # provided in initialize. Returns the capabilities that the
    # RETS server provides, per http://retsdoc.onconfluence.com/display/rets172/4.10+Capability+URL+List.
    def login
      request(uri.path)
      # return capabilities
    end

    def search(*todo)
      search_uri = capability("Search")
    end

    def request(path, body = nil, headers = build_headers, &reader)
      debug "posting to #{path}"

      post = Net::HTTP::Post.new(path, headers)
      post.body = body.to_s

      connection_args = [Net::HTTP::Persistent === connection ? uri : nil, post].compact

      response = connection.request(*connection_args) do |res|
        res.read_body(&block)
      end

      # handle cookies

      if block_given?
        return response
      else
        return handle_response(response)
      end
    end


    def connection
      @connection ||= options[:persistent] ?
        Net::HTTP::Persistent.new :
        Net::HTTP.new(uri.host, uri.port)
    end



  end
end
