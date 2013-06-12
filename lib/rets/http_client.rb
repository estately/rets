module Rets
  class HttpClient
    attr_reader :http, :options, :logger, :login_url

    def initialize(http, options, logger, login_url)
      @http = http
      @options = options
      @logger = logger
      @login_url = login_url
    end

    def http_get(url, params=nil, extra_headers={})
      http.set_auth(url, options[:username], options[:password])
      headers = extra_headers.merge(rets_extra_headers)
      res = http.get(url, params, headers)
      log_http_traffic("POST", url, params, headers, res)
      ErrorChecker.check(res)
      res
    end

    def http_post(url, params, extra_headers = {})
      http.set_auth(url, options[:username], options[:password])
      headers = extra_headers.merge(rets_extra_headers)
      res = http.post(url, params, headers)
      log_http_traffic("POST", url, params, headers, res)
      ErrorChecker.check(res)
      res
    end


    def log_http_traffic(method, url, params, headers, res)
      return unless logger.debug?
      logger.debug "Rets::Client >> #{method} #{url}"
      logger.debug "Rets::Client >> params = #{params.inspect}"
      logger.debug "Rets::Client >> headers = #{headers.inspect}"
      logger.debug "Rets::Client << Status #{res.status_code}"
      res.headers.each { |k, v| logger.debug "Rets::Client << #{k}: #{v}" }
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
        if response.status_code == 401
          raise AuthorizationFailure, "HTTP status: #{response.status_code}, body: #{response.body}"
        else
          raise HttpError, "HTTP status: #{response.status_code}, body: #{response.body}"
        end
      end
    end
  end
end
