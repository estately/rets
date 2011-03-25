module Rets

  Session = Struct.new(:authorization, :capabilities, :cookies)

  class Client
    DEFAULT_OPTIONS = { :persistent => true }

    include Authentication

    attr_accessor :uri, :options, :authorization
    attr_writer   :capabilities

    def initialize(options)
      uri          = URI.parse(options[:login_url])

      uri.user     = options.key?(:username) ? CGI.escape(options[:username]) : nil
      uri.password = options.key?(:password) ? CGI.escape(options[:password]) : nil

      self.options = DEFAULT_OPTIONS.merge(options)
      self.uri     = uri

      self.session = options[:session] if options[:session]
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

    def raw_request(path, body = nil, headers = build_headers, &reader)
      logger.info "posting to #{path}"

      post = Net::HTTP::Post.new(path, headers)
      post.body = body.to_s

      connection_args = [Net::HTTP::Persistent === connection ? uri : nil, post].compact

      response = connection.request(*connection_args) do |res|
        res.read_body(&reader)
      end

      handle_cookies(response)

      return response
    end

    def request(*args, &block)
      handle_response(raw_request(*args, &block))
    end

    def handle_unauthorized_response(response)
      self.authorization = build_auth(response['www-authenticate'], uri, tries)

      response = raw_request(uri.path)

      if Net::HTTPUnauthorized === response
        raise AuthorizationFailure, "Authorization failed, check credentials?"
      else
        capabilities = extract_capabilities(Nokogiri.parse(response.body))

        self.capabilities = capabilities
      end
    end

    def handle_response(response)

      if Net::HTTPUnauthorized === response
        handle_unauthorized_response(response)

      else
        begin
          if !response.body.empty?
            xml = Nokogiri::XML.parse(response.body, nil, nil, Nokogiri::XML::ParseOptions::STRICT)

            reply_text = xml.xpath("//RETS").attr("ReplyText").value
            reply_code = xml.xpath("//RETS").attr("ReplyCode").value.to_i

            if reply_code.nonzero?
              raise InvalidRequest, "Got error code #{reply_code} (#{reply_text})."
            end
          end

        rescue Nokogiri::XML::SyntaxError => e
          logger.debug "Not xml"

        end
      end

      return response
    end


    def handle_cookies(response)
      if cookies?(response)
        self.cookies = response.get_fields('set-cookie')
        logger.info "Cookies set to #{cookies.inspect}"
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


    def session=(session)
      self.authorization = session.authorization
      self.capabilities  = session.capabilities
      self.cookies       = session.cookies
    end

    def session
      Session.new(authorization, capabilities, cookies)
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


    def user_agent
      options[:agent] || "Client/1.0"
    end

    def rets_version
      options[:version] || "RETS/1.7.2"
    end

    def build_headers
      headers = {
        "User-Agent"   => user_agent,
        "Host"         => "#{uri.host}:#{uri.port}",
        "RETS-Version" => rets_version
      }

      headers.merge!("Authorization" => authorization) if authorization
      headers.merge!("Cookie" => cookies)              if cookies

      if options[:ua_password]
        headers.merge!(
          "RETS-UA-Authorization" => build_user_agent_auth(
            user_agent, options[:ua_password], cookie("RETS-Session-ID"), rets_version))
      end

      headers
    end


    def tries
      @tries ||= 0

      (@tries += 1) - 1
    end

    def logger
      options[:logger] || FakeLogger.new
    end

    class FakeLogger
      def fatal(*_); end
      def error(*_); end
      def warn(*_);  end
      def info(*_);  end
      def debug(*_); end
    end

  end
end
