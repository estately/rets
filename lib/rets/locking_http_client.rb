module Rets
  class LockingHttpClient
    def initialize(http_client, locker, lock_name, options={})
      @http_client = http_client
      @locker = locker
      @lock_name = lock_name
      @options = options
    end

    def http_get(url, params=nil, extra_headers={})
      lock_around do
        @http_client.http_get(url, params, extra_headers)
      end
    end

    def http_post(url, params, extra_headers = {})
      lock_around do
        @http_client.http_post(url, params, extra_headers)
      end
    end

    def save_cookie_store
      @http_client.save_cookie_store
    end

    def lock_around(&block)
      result = nil
      @locker.lock(@lock_name, @options) do
        result = block.call
      end
      result
    end
  end
end
