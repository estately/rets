module Rets
  # Adapted from dbrain's Net::HTTP::DigestAuth gem, and RETS4R auth
  # in order to support RETS' usage of digest authentication.
  module Authentication
    def build_auth(digest_authenticate, uri, nc = 0, method = "POST")
      user     = CGI.unescape uri.user
      password = CGI.unescape uri.password

      digest_authenticate =~ /^(\w+) (.*)/

      params = {}
      $2.gsub(/(\w+)="(.*?)"/) { params[$1] = $2 }

      cnonce = Digest::MD5.hexdigest "%x" % (Time.now.to_i + rand(65535))

      digest = calculate_digest(
        user, password, params['realm'], params['nonce'], method, uri.request_uri, params['qop'], cnonce, nc
      )

      header = [
        %Q(Digest username="#{user}"),
        %Q(realm="#{params['realm']}"),
        %Q(qop="#{params['qop']}"),
        %Q(uri="#{uri.request_uri}"),
        %Q(nonce="#{params['nonce']}"),
        %Q(nc=#{('%08x' % nc)}),
        %Q(cnonce="#{cnonce}"),
        %Q(response="#{digest}"),
        %Q(opaque="#{params['opaque']}"),
      ]

      header.join(", ")
    end

    def calculate_digest(user, password, realm, nonce, method, uri, qop, cnonce, nc)
      a1 = Digest::MD5.hexdigest "#{user}:#{realm}:#{password}"
      a2 = Digest::MD5.hexdigest "#{method}:#{uri}"

      if qop
        Digest::MD5.hexdigest("#{a1}:#{nonce}:#{'%08x' % nc}:#{cnonce}:#{qop}:#{a2}")
      else
        Digest::MD5.hexdigest("#{a1}:#{nonce}:#{a2}")
      end
    end

    def calculate_user_agent_digest(user_agent, user_agent_password, session_id, version)
      product, _ = user_agent.split("/")

      a1 = Digest::MD5.hexdigest "#{product}:#{user_agent_password}"

      Digest::MD5.hexdigest "#{a1}::#{session_id}:#{version}"
    end

    def build_user_agent_auth(*args)
      %Q(Digest "#{calculate_user_agent_digest(*args)}")
    end

  end
end
