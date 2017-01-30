require 'logger'

module Rets
  class Client
    COUNT = Struct.new(:exclude, :include, :only).new(0,1,2)
    CASE_INSENSITIVE_PROC = Proc.new { |h,k| h.key?(k.downcase) ? h[k.downcase] : nil }

    attr_accessor :cached_metadata, :client_progress, :logger, :login_url, :options

    def initialize(options)
      @options = options
      clean_setup
    end

    def clean_setup
      if options.fetch(:login_after_error, true)
        @capabilities = nil
      end
      @metadata            = nil
      @tries               = nil
      @login_url           = options[:login_url]
      @cached_metadata     = options[:metadata]
      @cached_capabilities = options[:capabilities]
      @logger              = options[:logger] || FakeLogger.new
      @client_progress     = ClientProgressReporter.new(logger, options[:stats_collector], options[:stats_prefix])
      @http_client         = Rets::HttpClient.from_options(options, logger)
      @caching             = Metadata::Caching.make(options)
    end

    # Attempts to login by making an empty request to the URL provided in
    # initialize. Returns the capabilities that the RETS server provides, per
    # page 34 of http://www.realtor.org/retsorg.nsf/retsproto1.7d6.pdf#page=34
    def login
      res = http_get(login_url)
      Parser::ErrorChecker.check(res)

      new_capabilities = extract_capabilities(Nokogiri.parse(res.body))
      unless new_capabilities
        raise UnknownResponse, "Cannot read rets server capabilities."
      end
      @capabilities = new_capabilities
    end

    def logout
      unless capabilities["Logout"]
        raise NoLogout.new('No logout method found for rets client')
      end
      http_get(capability_url("Logout"))
    rescue UnknownResponse => e
      unless e.message.match(/expected a 200, but got 401/)
        raise e
      end
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
      find_with_given_retry(retries, opts)
    end

    def find_with_given_retry(retries, opts)
      begin
        find_every(opts)
      rescue NoRecordsFound => e
        if opts.fetch(:no_records_not_an_error, false)
          client_progress.no_records_found
          opts[:count] == COUNT.only ? 0 : []
        else
          handle_find_failure(retries, opts, e)
        end
      rescue InvalidRequest, HttpError => e
        handle_find_failure(retries, opts, e)
      rescue AuthorizationFailure => e
        login
        handle_find_failure(retries, opts, e)
      end
    end

    def handle_find_failure(retries, opts, e)
      max_retries = fetch_max_retries(opts)
      if retries < max_retries
        retries += 1
        wait_before_next_request
        client_progress.find_with_retries_failed_a_retry(e, retries, max_retries)
        clean_setup
        find_with_given_retry(retries, opts)
      else
        client_progress.find_with_retries_exceeded_retry_count(e)
        raise e
      end
    end

    def fetch_max_retries(hash)
      hash[:max_retries] || options.fetch(:max_retries, 3)
    end

    def wait_before_next_request
      sleep_time = Float(options.fetch(:recoverable_error_wait_secs, 0))
      if sleep_time > 0
        logger.info "Waiting #{sleep_time} seconds before next attempt"
        sleep sleep_time
      end
    end

    def find_every(opts)
      raise ArgumentError.new("missing option :search_type (provide the name of a RETS resource)") unless opts[:search_type]
      raise ArgumentError.new("missing option :class (provide the name of a RETS class)") unless opts[:class]

      params = {
        "SearchType"          => opts.fetch(:search_type),
        "Class"               => opts.fetch(:class),
        "Count"               => opts[:count],
        "Format"              => opts.fetch(:format, "COMPACT"),
        "Limit"               => opts[:limit],
        "Offset"              => opts[:offset],
        "Select"              => opts[:select],
        "RestrictedIndicator" => opts[:RestrictedIndicator],
        "StandardNames"       => opts[:standard_name],
        "Payload"             => opts[:payload],
        "Query"               => opts[:query],
        "QueryType"           => opts.fetch(:query_type, "DMQL2"),
      }.reject { |k,v| v.nil? }
      res = clean_response(http_post(capability_url("Search"), params))

      if opts[:count] == COUNT.only
        Parser::Compact.get_count(res.body)
      else
        results = Parser::Compact.parse_document(
          res.body
        )
        if opts[:resolve]
          rets_class = find_rets_class(opts[:search_type], opts[:class])
          decorate_results(results, rets_class)
        else
          results
        end
      end
    end

    def find_rets_class(resource_name, rets_class_name)
      metadata.tree[resource_name].find_rets_class(rets_class_name)
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
          client_progress.could_not_resolve_find_metadata(key)
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
        when Array  then fetch_object(object_ids.join(":"), opts)
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

        logger.debug "Rets::Client: Found #{parts.size} parts"

        return parts
      else
        logger.debug "Rets::Client: Found 1 part (the whole body)"

        # fake a multipart for interface compatibility
        headers = {}
        response.headers.each { |k,v| headers[k.downcase] = v }
        part = Parser::Multipart::Part.new(headers, response.body)

        return [part]
      end
    end

    # Returns a single object.
    #
    # resource     RETS resource as defined in the resource metadata.
    # object_type  an object type defined in the object metadata.
    # resource_id  the KeyField value of the given resource instance.
    # object_id    can be "*" or a colon delimited string of integers or an array of integers.
    def object(object_id, opts = {})
      response = fetch_object(Array(object_id).join(':'), opts)
      response.body
    end

    def fetch_object(object_id, opts = {})
      params = {
        "Resource" => opts.fetch(:resource),
        "Type"     => opts.fetch(:object_type),
        "ID"       => "#{opts.fetch(:resource_id)}:#{object_id}",
        "Location" => opts.fetch(:location, 0)
      }

      extra_headers = {
        "Accept" => "image/jpeg, image/png;q=0.5, image/gif;q=0.1",
      }

      http_post(capability_url("GetObject"), params, extra_headers)
    end

    def metadata(types=nil)
      return @metadata if @metadata
      @cached_metadata ||= @caching.load(@logger)
      if cached_metadata && (options[:skip_metadata_uptodate_check] ||
          cached_metadata.current?(capabilities["MetadataTimestamp"], capabilities["MetadataVersion"]))
        client_progress.use_cached_metadata
        @metadata = cached_metadata
      else
        client_progress.bad_cached_metadata(cached_metadata)
        @metadata = Metadata::Root.new(logger, retrieve_metadata(types))
        @caching.save(metadata)
      end
      @metadata
    end

    def retrieve_metadata(types=nil)
      raw_metadata = {}
      (types || Metadata::METADATA_TYPES).each {|type|
        raw_metadata[type] = retrieve_metadata_type(type)
      }
      raw_metadata
    end

    def retrieve_metadata_type(type)
      res = http_post(capability_url("GetMetadata"),
                      { "Format" => "COMPACT",
                        "Type"   => "METADATA-#{type}",
                        "ID"     => "0"
                      })
      clean_response(res).body
    end

    # The capabilies as provided by the RETS server during login.
    #
    # Currently, only the path in the endpoint URLs is used[1]. Host,
    # port, other details remaining constant with those provided to
    # the constructor.
    #
    # [1] In fact, sometimes only a path is returned from the server.
    def capabilities
      if @capabilities
        @capabilities
      elsif @cached_capabilities
        @capabilities = add_case_insensitive_default_proc(@cached_capabilities)
      else
        login
      end
    end

    def capability_url(name)
      val = capabilities[name] || capabilities[name.downcase]

      raise UnknownCapability.new(name, capabilities.keys) unless val

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

      # ... :(
      # Feel free to make this better. It has a test.
      hash = raw_key_values.split(/\n/).
        map  { |r| r.split(/\=/, 2) }.
        each_with_object({}) { |(k,v), h| h[k.strip.downcase] = v.strip }

      add_case_insensitive_default_proc(hash)
    end

    def add_case_insensitive_default_proc(hash)
      new_hash = hash.dup
      new_hash.default_proc = CASE_INSENSITIVE_PROC
      new_hash
    end

    def save_cookie_store
      @http_client.save_cookie_store
    end

    def http_get(url, params=nil, extra_headers={})
      clean_response(@http_client.http_get(url, params, extra_headers))
    end

    def clean_response(res)
      res.body.encode!("UTF-8", res.body.encoding, :invalid => :replace, :undef => :replace)
      res
    end

    def http_post(url, params, extra_headers = {})
      @http_client.http_post(url, params, extra_headers)
    end

    def tries
      @tries ||= 1

      (@tries += 1) - 1
    end

    class FakeLogger < Logger
      def initialize
        super(IO::NULL)
      end
    end
  end
end
