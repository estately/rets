module Rets
  METADATA_TYPES = %w(SYSTEM RESOURCE CLASS TABLE LOOKUP LOOKUP_TYPE OBJECT)

  Session = Struct.new(:authorization, :capabilities, :cookies)

  class Client
    DEFAULT_OPTIONS = { :persistent => true }

    include Authentication

    attr_accessor :uri, :options, :authorization
    attr_writer   :capabilities

    def initialize(options)
      @capabilities = nil
      @cookies      = nil
      @metadata     = nil

      uri          = URI.parse(options[:login_url])

      uri.user     = options.key?(:username) ? CGI.escape(options[:username]) : nil
      uri.password = options.key?(:password) ? CGI.escape(options[:password]) : nil

      self.options = DEFAULT_OPTIONS.merge(options)
      self.uri     = uri

      self.session  = options[:session]  if options[:session]
      self.metadata = options[:metadata] if options[:metadata]
    end


    # Attempts to login by making an empty request to the URL
    # provided in initialize. Returns the capabilities that the
    # RETS server provides, per http://retsdoc.onconfluence.com/display/rets172/4.10+Capability+URL+List.
    def login
      request(uri.path)
      capabilities
    end

    # Finds records.
    #
    # [quantity]  Return the first record, or an array of records.
    #             Uses a symbol <tt>:first</tt> or <tt>:all</tt>, respectively.
    #
    # [opts]  A hash of arguments used to construct the search query,
    #         using the following keys:
    #
    # <tt>:search_type</tt>::  Required. The resource to search for.
    # <tt>:class</tt>::        Required. The class of the resource to search for.
    # <tt>:query</tt>::        Required. The DMQL2 query string to execute.
    # <tt>:limit</tt>::        The number of records to request from the server.
    #
    # Any other keys are converted to the RETS query format, and passed
    # to the server as part of the query. For instance, the key <tt>:offset</tt>
    # will be sent as +Offset+.
    #
    def find(quantity, opts = {})
      case quantity
        when :first  then find_every(opts.merge(:limit => 1)).first
        when :all    then find_every(opts)
        else raise ArgumentError, "First argument must be :first or :all"
      end
    end

    alias search find

    def find_every(opts = {})
      search_uri = capability_url("Search")

      opts = fixup_keys(opts)

      defaults = {"QueryType" => "DMQL2", "Format" => "COMPACT"}

      query = defaults.merge(opts)

      body = build_key_values(query)

      headers = build_headers.merge(
        "Content-Type"   => "application/x-www-form-urlencoded",
        "Content-Length" => body.size.to_s
      )

      request_with_compact_response(search_uri.path, body, headers)
    end

    # Returns an array of all objects associated with the given resource.
    def all_objects(opts = {})
      objects("*", opts)
    end

    # Returns an array of specified objects.
    def objects(object_ids, opts = {})
      response = case object_ids
        when String then fetch_object(object_ids, opts)
        when Array  then fetch_object(object_ids.join(","), opts)
        else raise ArgumentError, "Expected instance of String or Array, but got #{object_ids.inspect}."
      end

      create_parts_from_response(response)
    end

    def create_parts_from_response(response)
      content_type = response["content-type"]

      if content_type.include?("multipart")
        boundary = content_type.scan(/boundary="(.*?)"/).to_s

        parts = Parser::Multipart.parse(response.body, boundary)

        logger.debug "Found #{parts.size} parts"

        return parts
      else
        # fake a multipart for interface compatibility
        headers = {}
        response.each { |k,v| headers[k] = v }

        part = Parser::Multipart::Part.new(headers, response.body)

        return [part]
      end
    end

    # Returns a single object.
    #
    # resource     RETS resource as defined in the resource metadata.
    # object_type  an object type defined in the object metadata.
    # resource_id  the KeyField value of the given resource instance.
    # object_id    can be "*", or a comma delimited string of one or more integers.
    def object(object_id, opts = {})
      response = fetch_object(object_id, opts)

      response.body
    end

    def fetch_object(object_id, opts = {})
      object_uri = capability_url("GetObject")

      body = build_key_values(
        "Resource" => opts[:resource],
        "Type"     => opts[:object_type],
        "ID"       => "#{opts[:resource_id]}:#{object_id}",
        "Location" => 0
      )

      headers = build_headers.merge(
        "Accept"         => "image/jpeg, image/png;q=0.5, image/gif;q=0.1",
        "Content-Type"   => "application/x-www-form-urlencoded",
        "Content-Length" => body.size.to_s
      )

      request(object_uri.path, body, headers)
    end

    # Changes keys to be camel cased, per the RETS standard for queries.
    def fixup_keys(hash)
      fixed_hash = {}

      hash.each do |key, value|
        camel_cased_key = key.to_s.capitalize.gsub(/_(\w)/) { $1.upcase }

        fixed_hash[camel_cased_key] = value
      end

      fixed_hash
    end

    def metadata_current?(system_metadata)
      remote_metadata_timestamp = capabilities["MetadataTimestamp"]
      our_metadata_timestamp    = system_metadata.date

      remote_metadata_version   = capabilities["MetadataVersion"]
      our_metadata_version      = system_metadata.version

      (remote_metadata_version ? remote_metadata_version == our_metadata_version : true) &&
        (remote_metadata_timestamp ? remote_metadata_timestamp == our_metadata_timestamp : true)
    end

    def metadata=(metadata)
      @metadata = metadata
    end

    def metadata
      return @metadata if @metadata && metadata_current?(@metadata[:system].first)

      @metadata = {}

      METADATA_TYPES.each do |type|
        @metadata[type.downcase.to_sym] = Metadata.build(metadata_type(type))
      end

      @metadata
    end

    def metadata_type(type)
      metadata_uri = capability_url("GetMetadata")

      body = build_key_values(
        "Format" => "COMPACT",
        "Type"   => "METADATA-#{type}",
        "ID"     => "0"
      )

      headers = build_headers.merge(
        "Content-Type"   => "application/x-www-form-urlencoded",
        "Content-Length" => body.size.to_s
      )

      response = request(metadata_uri.path, body, headers)

      Nokogiri.parse(response.body)
    end

    def raw_request(path, body = nil, headers = build_headers, &reader)
      logger.info "posting to #{path}"

      post = Net::HTTP::Post.new(path, headers)
      post.body = body.to_s

      logger.debug headers.inspect
      logger.debug body.to_s

      connection_args = [Net::HTTP::Persistent === connection ? uri : nil, post].compact

      response = connection.request(*connection_args) do |res|
        res.read_body(&reader)
      end

      handle_cookies(response)

      logger.debug response.class
      logger.debug response.body

      return response
    end

    def request(*args, &block)
      handle_response(raw_request(*args, &block))
    end

    def request_with_compact_response(path, body, headers)
      response = request(path, body, headers)

      Parser::Compact.parse_document response.body
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

      if Net::HTTPUnauthorized === response # 401
        handle_unauthorized_response(response)

      elsif Net::HTTPSuccess === response # 2xx
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

      else
        raise UnknownResponse, "Unable to handle response #{response.class}"
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

    def capability_url(name)
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

      h = Hash.new{|h,k| h.key?(k.downcase) ? h[k.downcase] : nil }

      # ... :(
      # Feel free to make this better. It has a test.
      raw_key_values.split(/\n/).
        map  { |r| r.split(/=/, 2) }.
        each { |k,v| h[k.strip.downcase] = v }

      h
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

    def build_key_values(data)
      data.map{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join("&")
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
