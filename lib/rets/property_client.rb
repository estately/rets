module Rets
  class PropertyClient
    attr_reader :rets_client

    def initialize(config)
      @config = config
      @rets_client = Rets::Client.new(@config.client_params)
    end

    def property(params={})
      @rets_client.find(:first, build_property_params(params)) || {}
    end

    def properties(params={})
      @rets_client.find(:all, build_property_params(params))
    end

    def property_count(params={})
      @rets_client.find(:all, build_property_params(params.merge(count: 2)))
    end

    def build_property_params(params={})
      query = params[:query] || ''
      date = date_query(@config.property_modified_key_field, params[:start_at], params[:end_at])
      final_query = [base_property_query, query, date].reject { |c| c.empty? }.join(',')
      params[:query] = final_query
      property_params.merge(params.reject{ |k, v| [:start_at, :end_at].include?(k) })
    end

    private
    def base_property_query
      @config.property_key_field_numeric? ? "(#{@config.property_key_field}=0+)" : "(#{@config.property_key_field}=*)"
    end

    def date_query(field, start_at, end_at)
      if start_at && end_at
        "(#{field}=#{format_datetime(start_at)}-#{format_datetime(end_at)})"
      elsif start_at
        "(#{field}=#{format_datetime(start_at)}+)"
      elsif end_at
        "(#{field}=#{format_datetime(end_at)}-)"
      else
        ''
      end
    end

    # Discuss: Do any MLSes require querying modified datetimes with a utc offset but also
    # don't accept the offset with the datetime?
    def format_datetime(value)
      time =
        if value.is_a?(String)
          Time.parse(value)
        else
          value
        end

      if @config.modified_field_accepts_offset?
        time.utc.strftime('%FT%T%:z')
      else
        time.utc.strftime('%Y-%m-%dT%H:%M:%S')
      end
    end

    def property_params
      { :search_type => @config.property_resource_type, :no_records_not_an_error => true, :class => @config.property_class, :format => 'COMPACT-DECODED' }
    end
  end
end
