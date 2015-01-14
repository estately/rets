module Rets
  class HttpClient
    attr_reader :http, :options, :logger, :login_url

    def initialize(http, options, logger, login_url)
      @http = http
      @options = options
      @logger = logger
      @login_url = login_url
      @options.fetch(:ca_certs, []).each {|c| @http.ssl_config.add_trust_ca(c) }
    end

    def http_get(url, params=nil, extra_headers={})
      http.set_auth(url, options[:username], options[:password])
      headers = extra_headers.merge(rets_extra_headers)
      res = nil
      log_http_traffic("GET", url, params, headers) do
        res = http.get(url, params, headers)
      end
      Client::ErrorChecker.check(res)
      res
    end

    def http_post(url, params, extra_headers = {})
      http.set_auth(url, options[:username], options[:password])
      headers = extra_headers.merge(rets_extra_headers)
      res = nil
      log_http_traffic("POST", url, params, headers) do
        res = http.post(url, params, headers)
      end
      Client::ErrorChecker.check(res)
      res
    end

    def log_http_traffic(method, url, params, headers, &block)
      # optimization, we don't want to compute log params
      # if logging is off
      if logger.debug?
        logger.debug "Rets::Client >> #{method} #{url}"
        logger.debug "Rets::Client >> params = #{params.inspect}"
        logger.debug "Rets::Client >> headers = #{headers.inspect}"
      end

      res = block.call

      # optimization, we don't want to compute log params
      # if logging is off, especially when there is a loop just
      # for logging
      if logger.debug?
        logger.debug "Rets::Client << Status #{res.status_code}"
        res.headers.each { |k, v| logger.debug "Rets::Client << #{k}: #{v}" }
      end
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

    def http_cookie(name)
      http.cookies.each do |c|
        return c.value if c.name.downcase == name.downcase && c.match?(URI.parse(login_url))
      end
      nil
    end
  end
end
