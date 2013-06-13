module Rets
  class MeasuringHttpClient
    def initialize(http_client, stats, prefix)
      @http_client = http_client
      @stats = stats
      @prefix = prefix
    end

    def http_get(url, params=nil, extra_headers={})
      @stats.time("#{@prefix}.http_get") do
        @http_client.http_get(url, params, extra_headers)
      end
    end

    def http_post(url, params, extra_headers = {})
      @stats.time("#{@prefix}.http_post") do
        @http_client.http_post(url, params, extra_headers)
      end
    end

    def save_cookie_store(force=nil)
      @http_client.save_cookie_store(force)
    end
  end
end
