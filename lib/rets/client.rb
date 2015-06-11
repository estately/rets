require 'http-cookie'
require 'httpclient'
require 'logger'

module Rets
  class HttpError < StandardError ; end

  class Client
    COUNT = Struct.new(:exclude, :include, :only).new(0,1,2)

    attr_accessor :cached_metadata, :client_progress, :logger, :login_url, :options

    def initialize(options)
      @options = options
      clean_setup
    end

    def clean_setup
      @metadata        = nil
      @tries           = nil
      @login_url       = options[:login_url]
      @cached_metadata = options[:metadata]
      @capabilities    = options[:capabilities]
      @logger          = options[:logger] || FakeLogger.new
      @client_progress = ClientProgressReporter.new(logger, options[:stats_collector], options[:stats_prefix])
      @http_client     = Rets::HttpClient.from_options(options, logger)
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
      new_capabilities
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
      resolve = opts.delete(:resolve)
      find_with_given_retry(retries, resolve, opts)
    end

    def find_with_given_retry(retries, resolve, opts)
      begin
        find_every(opts, resolve)
      rescue NoRecordsFound => e
        if opts.fetch(:no_records_not_an_error, false)
          client_progress.no_records_found
          opts[:count] == COUNT.only ? 0 : []
        else
          handle_find_failure(retries, resolve, opts, e)
        end
      rescue AuthorizationFailure, InvalidRequest => e
        handle_find_failure(retries, resolve, opts, e)
      end
    end

    def handle_find_failure(retries, resolve, opts, e)
      if retries < opts.fetch(:max_retries, 3)
        retries += 1
        client_progress.find_with_retries_failed_a_retry(e, retries)
        clean_setup
        find_with_given_retry(retries, resolve, opts)
      else
        client_progress.find_with_retries_exceeded_retry_count(e)
        raise e
      end
    end

    def find_every(opts, resolve)
      params = {"QueryType" => "DMQL2", "Format" => "COMPACT"}.merge(fixup_keys(opts))
      res = http_post(capability_url("Search"), params)

      if opts[:count] == COUNT.only
        Parser::Compact.get_count(res.body)
      else
        results = Parser::Compact.parse_document(
          res.body.encode("UTF-8", res.body.encoding, :invalid => :replace, :undef => :replace)
        )
        if resolve
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

        logger.debug "Rets::Client: Found #{parts.size} parts"

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

      if cached_metadata && (options[:skip_metadata_uptodate_check] ||
          cached_metadata.current?(capabilities["MetadataTimestamp"], capabilities["MetadataVersion"]))
        client_progress.use_cached_metadata
        @metadata = cached_metadata
      else
        client_progress.bad_cached_metadata(cached_metadata)
        @metadata = Metadata::Root.new(logger, retrieve_metadata)
      end
    end

    def retrieve_metadata
      raw_metadata = {}
      Metadata::METADATA_TYPES.each {|type|
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
      @capabilities ||= login
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

      hash = Hash.new{|h,k| h.key?(k.downcase) ? h[k.downcase] : nil }

      # ... :(
      # Feel free to make this better. It has a test.
      raw_key_values.split(/\n/).
        map  { |r| r.split(/\=/, 2) }.
        each { |k,v| hash[k.strip.downcase] = v.strip }

      hash
    end

    def save_cookie_store(force=nil)
      @http_client.save_cookie_store(force)
    end

    def http_get(url, params=nil, extra_headers={})
      @http_client.http_get(url, params, extra_headers)
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
