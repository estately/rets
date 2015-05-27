require 'uri'
require 'digest/md5'
require 'nokogiri'

module Rets
  VERSION = '0.7.0'

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

  class NoRecordsFound < ArgumentError
    ERROR_CODE = 20201
    attr_reader :reply_text

    def initialize(reply_text)
      @reply_text = reply_text
      super("Got error code #{ERROR_CODE} (#{reply_text})")
    end
  end

  class NoObjectFound < ArgumentError
    ERROR_CODE = 20403
    attr_reader :reply_text

    def initialize(reply_text)
      @reply_text = reply_text
      super("Got error code #{ERROR_CODE} (#{reply_text})")
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
    attr_reader :capability_name, :capabilities
    def initialize(capability_name, capabilities=[])
      @capability_name = capability_name
      @capabilities = capabilities
      super("unknown capability #{capability_name}, available capabilities #{capabilities}")
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
