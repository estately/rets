require 'httpclient'

module Rets
  class HttpError < StandardError ; end

  class Client
    DEFAULT_OPTIONS = {}

    attr_accessor :login_url, :options, :logger
    attr_writer   :capabilities, :metadata

    def initialize(options)
      @options = options
      clean_setup
    end

    def clean_setup
      self.options     = DEFAULT_OPTIONS.merge(@options)
      self.login_url   = self.options[:login_url]

      @cached_metadata   = nil
      @capabilities      = nil
      @metadata          = nil
      @tries             = nil
      self.capabilities  = nil

      self.logger      = @options[:logger] || FakeLogger.new
      @cached_metadata = @options[:metadata] || nil
    end

    # Attempts to login by making an empty request to the URL
    # provided in initialize. Returns the capabilities that the
    # RETS server provides, per http://retsdoc.onconfluence.com/display/rets172/4.10+Capability+URL+List.
    def login
      res = http_get(login_url)
      self.capabilities = extract_capabilities(Nokogiri.parse(res.body))
      raise UnknownResponse, "Cannot read rets server capabilities." unless @capabilities
      @capabilities
    end

    def logout
      http_get capability_url("Logout")
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
    # <tt>:resolve</tt>::      Provide resolved values that use metadata instead
    #                          of raw system values.
    #
    # Any other keys are converted to the RETS query format, and passed
    # to the server as part of the query. For instance, the key <tt>:offset</tt>
    # will be sent as +Offset+.
    #
    def find(quantity, opts = {})
      case quantity
        when :first  then find_with_retries(opts.merge(:limit => 1)).first
        when :all    then find_with_retries(opts)
        else raise ArgumentError, "First argument must be :first or :all"
      end
    end

    alias search find

    def find_with_retries(opts = {})
      retries = 0
      resolve = opts.delete(:resolve)
      begin
        find_every(opts, resolve)
      rescue AuthorizationFailure, InvalidRequest => e
        if retries < 3
          retries += 1
          self.logger.warn "Failed with message: #{e.message}"
          self.logger.info "Retry #{retries}/3"
          clean_setup
          retry
        else
          raise e
        end
      end
    end

    def find_every(opts, resolve)
      params = {"QueryType" => "DMQL2", "Format" => "COMPACT"}.merge(fixup_keys(opts))
      res = http_post(capability_url("Search"), params)
      results = Parser::Compact.parse_document res.body

      if resolve
        rets_class = find_rets_class(opts[:search_type], opts[:class])
        decorate_results(results, rets_class)
      else
        results
      end
    end

    def find_rets_class(resource_name, rets_class_name)
      metadata.build_tree[resource_name].find_rets_class(rets_class_name)
    end

    def decorate_results(results, rets_class)
      results.map do |result|
        decorate_result(result, rets_class)
      end
    end

    def decorate_result(result, rets_class)
      result.each do |key, value|
        table = rets_class.find_table(key)
        if table
          result[key] = table.resolve(value.to_s)
        else
          #can't resolve just leave the value be
          logger.warn "Can't resolve find metadata for #{key.inspect}"
        end
      end
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
      content_type = response.header["content-type"][0]

      if content_type.nil?
        raise MalformedResponse, "Unable to read content-type from response: #{response.inspect}"
      end

      if content_type.include?("multipart")
        boundary = content_type.scan(/boundary="?([^;"]*)?/).join

        parts = Parser::Multipart.parse(response.body, boundary)

        logger.debug "Found #{parts.size} parts"

        return parts
      else
        # fake a multipart for interface compatibility
        headers = {}
        response.headers.each { |k,v| headers[k] = v[0] }

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
      params = {
        "Resource" => opts[:resource],
        "Type"     => opts[:object_type],
        "ID"       => "#{opts[:resource_id]}:#{object_id}",
        "Location" => opts[:location] || 0
      }

      extra_headers = {
        "Accept" => "image/jpeg, image/png;q=0.5, image/gif;q=0.1",
      }

      http_post(capability_url("GetObject"), params, extra_headers)
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

    def metadata
      return @metadata if @metadata

      if @cached_metadata && (@options[:skip_metadata_uptodate_check] ||
          @cached_metadata.current?(capabilities["MetadataTimestamp"], capabilities["MetadataVersion"]))
        logger.info "Use cached metadata"
        self.metadata = @cached_metadata
      else
        logger.info @cached_metadata ? "Cached metadata out of date" : "Cached metadata unavailable"
        metadata_fetcher = lambda { |type| retrieve_metadata_type(type) }
        self.metadata = Metadata::Root.new(&metadata_fetcher)
      end
    end

    def retrieve_metadata_type(type)
      res = http_post(capability_url("GetMetadata"),
                      { "Format" => "COMPACT",
                        "Type"   => "METADATA-#{type}",
                        "ID"     => "0"
                      })
      res.body
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
      val = capabilities[name]

      begin
        if val.downcase.match(/^https?:\/\//)
          uri = URI.parse(val)
        else
          uri = URI.parse(login_url)
          uri.path = val
        end
      rescue URI::InvalidURIError
        raise MalformedResponse, "Unable to parse capability URL: #{name} => #{val.inspect}"
      end
      uri.to_s
    end

    def extract_capabilities(document)
      raw_key_values = document.xpath("/RETS/RETS-RESPONSE").text.strip

      hash = Hash.new{|h,k| h.key?(k.downcase) ? h[k.downcase] : nil }

      # ... :(
      # Feel free to make this better. It has a test.
      raw_key_values.split(/\n/).
        map  { |r| r.split(/=/, 2) }.
        each { |k,v| hash[k.strip.downcase] = v.strip }

      hash
    end

    def http
      return @http if @http

      @http = HTTPClient.new
      @http.set_cookie_store(options[:cookie_store]) if options[:cookie_store]
      @http
    end

    def save_cookie_store(force=nil)
      if options[:cookie_store]
        if force
          @http.cookie_manager.save_all_cookies(true, true, true)
        else
          @http.save_cookie_store
        end
      end
    end

    def http_cookie(name)
      http.cookies.each do |c|
        return c.value if c.name.downcase == name.downcase && c.match?(URI.parse(login_url))
      end
      nil
    end

    def http_get(url, params=nil, extra_headers={})
      http.set_auth(url, options[:username], options[:password])
      res = http.get(url, params, extra_headers.merge(rets_extra_headers))
      ErrorChecker.check(res)
      res
    end

    def http_post(url, params, extra_headers = {})
      http.set_auth(url, options[:username], options[:password])
      res = http.post(url, params, extra_headers.merge(rets_extra_headers))
      ErrorChecker.check(res)
      res
    end

    def rets_extra_headers
      user_agent = options[:agent] || "Client/1.0"
      rets_version = options[:version] || "RETS/1.7.2"

      headers = {
        "User-Agent"   => user_agent,
        "RETS-Version" => rets_version
      }

      if options[:ua_password]
        up = Digest::MD5.hexdigest "#{user_agent}:#{options[:ua_password]}"
        session_id = http_cookie('RETS-Session-ID') || ''
        digest = Digest::MD5.hexdigest "#{up}::#{session_id}:#{rets_version}"
        headers.merge!("RETS-UA-Authorization" => "Digest #{digest}")
      end

      headers
    end

    def tries
      @tries ||= 1

      (@tries += 1) - 1
    end

    class FakeLogger
      def fatal(*); end
      def error(*); end
      def warn(*);  end
      def info(*);  end
      def debug(*); end
    end

    class ErrorChecker
      def self.check(response)
        # some RETS servers return success code in XML body but failure code 4xx in http status
        # If xml body is present we ignore http status

        if !response.body.empty?
          begin
            xml = Nokogiri::XML.parse(response.body, nil, nil, Nokogiri::XML::ParseOptions::STRICT)

            rets_element = xml.xpath("/RETS")
            reply_text = (rets_element.attr("ReplyText") || rets_element.attr("replyText")).value
            reply_code = (rets_element.attr("ReplyCode") || rets_element.attr("replyCode")).value.to_i

            if reply_code.nonzero?
              raise InvalidRequest, "Got error code #{reply_code} (#{reply_text})."
            else
              return
            end
          rescue Nokogiri::XML::SyntaxError
            #Not xml
          end
        end

        if response.respond_to?(:ok?) && ! response.ok?
          raise HttpError, "HTTP status: #{response.status_code}, body: #{response.body}"
        end
      end
    end
  end
end
