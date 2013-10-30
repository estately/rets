require 'uri'
require 'digest/md5'
require 'nokogiri'

module Rets
  VERSION = '0.5.1'

  MalformedResponse    = Class.new(ArgumentError)
  UnknownResponse      = Class.new(ArgumentError)
  NoLogout             = Class.new(ArgumentError)

  class AuthorizationFailure < ArgumentError
    attr_reader :status, :body
    def initialize(status, body)
      @status = status
      @body = body
      super("HTTP status: #{status} (#{body})")
    end
  end

  class InvalidRequest < ArgumentError
    attr_reader :error_code, :reply_text
    def initialize(error_code, reply_text)
      @error_code = error_code
      @reply_text = reply_text
      super("Got error code #{error_code} (#{reply_text})")
    end
  end

  class UnknownCapability < ArgumentError
    attr_reader :capability_name
    def initialize(capability_name)
      @capability_name = capability_name
      super("unknown capabilitiy #{capability_name}")
    end
  end
end

require 'rets/client'
require 'rets/metadata'
require 'rets/parser/compact'
require 'rets/parser/multipart'
require 'rets/measuring_http_client'
require 'rets/locking_http_client'
require 'rets/client_progress_reporter'
