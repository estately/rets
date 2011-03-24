require 'net/http'
require 'uri'
require 'cgi'
require 'digest/md5'

require 'rubygems'
require 'net/http/persistent'
require 'nokogiri'

module Rets
  VERSION = '0.0.1'

  InvalidRequest    = Class.new(ArgumentError)
  MalformedResponse = Class.new(ArgumentError)

  class Client
    DEFAULT_OPTIONS = { :persistent => true }

    attr_accessor :uri, :options
    attr_writer   :capabilities

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
      capabilities
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

      handle_cookies(response)

      # The provided block will be reading the response body,
      # so we will not do any further processing here.
      #
      # If there is no block, then the body is accessible as
      # usual in response.body, and we should inspect it in
      # order to determine the next action.
      if block_given?
        return response
      else
        return handle_response(response)
      end
    end

    def handle_response(response)

      # TODO: detect other types of possible login methods here.
      if Net::HTTPUnauthorized === response
        # TODO login with digest should make a request and check the response.
        # if the response is 401, then raise, else call handle_response.
        # TODO handle capabilities extraction here also?

        login_with_digest(uri.path, response['www-authenticate'])

      else
        begin
          if !response.body.empty?
            xml = Nokogiri::XML.parse(response.body, nil, nil, Nokogiri::XML::ParseOptions::STRICT)

            reply_text = xml.xpath("//RETS").attr("ReplyText").value
            reply_code = xml.xpath("//RETS").attr("ReplyCode").value.to_i

            if reply_code.nonzero?
              raise InvalidRequest, "Got error code #{reply_code} (#{reply_text})."
            end

            # TODO: investigate adding this extraction as part of login handler
            self.capabilities = extract_capabilities(xml) if capabilities_needed?
          end

        rescue Nokogiri::XML::SyntaxError => e
          debug "Not xml"

        end
      end

      return response
    end


    def handle_cookies(response)
      if cookies?(response)
        self.cookies = response.get_fields('set-cookie')
        debug "Cookies set to #{cookies.inspect}"
      end
    end

    def cookies?(response)
      response['set-cookie']
    end

    def cookies=(cookies)
      @cookies ||= {}

      cookies.each do |cookie|
        cookie.match(/(\S+)=([^;]+);?/)

        @cookies[$1] = $2
      end

      nil
    end

    def cookies
      return if @cookies.nil? or @cookies.empty?

      @cookies.map{ |k,v| "#{k}=#{v}" }.join("; ")
    end


    # The capabilies as provided by the RETS server during login.
    #
    # Currently, only the path in the endpoint URLs is used[1]. Host,
    # port, other details remaining constant with those provided to
    # the constructor.
    #
    # [1] In fact, sometimes only a path is returned from the server.
    def capabilities
      @capabilities || login
    end

    def capabilities_needed?
      @capabilities.nil?
    end

    def capability(name)
      url = capabilities[name]

      begin
        capability_uri = URI.parse(url)
      rescue URI::InvalidURIError => e
        raise MalformedResponse, "Unable to parse capability URL: #{url.inspect}"
      end

      capability_uri
    end

    def extract_capabilities(document)
      raw_key_values = document.xpath("//RETS/RETS-RESPONSE").text.strip

      # ... :(
      # Feel free to make this better. It has a test.
      key_values = raw_key_values.split(/\n/).map{ |r| r.split(/=/, 2).map { |k,v| [k.strip, v].join } }

      Hash[*key_values.flatten]
    end



    def connection
      @connection ||= options[:persistent] ?
        Net::HTTP::Persistent.new :
        Net::HTTP.new(uri.host, uri.port)
    end

    def build_headers
      {}
    end

    def debug(*lines)
      puts lines if $DEBUG
    end



  end
end
