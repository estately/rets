require 'uri'
require 'digest/md5'
require 'nokogiri'

module Rets
  VERSION = '0.11.0'

  HttpError            = Class.new(StandardError)
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

  class SystemError < InvalidRequest
    ERROR_CODE = 10000
  end

  class ZeroBalance < InvalidRequest
    ERROR_CODE = 20003
  end

  class BrokerCodeRequired < InvalidRequest
    ERROR_CODE = 20012
  end

  class AdditionalLoginNotPermitted < InvalidRequest
    ERROR_CODE = 20022
  end

  class ServerLoginError < InvalidRequest
    ERROR_CODE = 20036
  end

  class ClientAuthenticationFailed < InvalidRequest
    ERROR_CODE = 20037
  end

  class UserAgentAuthenticationRequired < InvalidRequest
    ERROR_CODE = 20041
  end

  class ServerTemporarilyDisabled < InvalidRequest
    ERROR_CODE = 20050
  end

  class InsecurePassword < InvalidRequest
    ERROR_CODE = 20140
  end

  class SameAsPreviousPassword < InvalidRequest
    ERROR_CODE = 20141
  end

  class InvalidUserName < InvalidRequest
    ERROR_CODE = 20142
  end

  class UnknownQueryField < InvalidRequest
    ERROR_CODE = 20200
  end

  class InvalidSelect < InvalidRequest
    ERROR_CODE = 20202
  end

  class MiscellaneousSearchError < InvalidRequest
    ERROR_CODE = 20203
  end

  class InvalidQuerySyntax < InvalidRequest
    ERROR_CODE = 20206
  end

  class UnauthorizedQuery < InvalidRequest
    ERROR_CODE = 20207
  end

  class MaximumRecordsExceeded < InvalidRequest
    ERROR_CODE = 20208
  end

  class RequestTimeout < InvalidRequest
    ERROR_CODE = 20209
  end

  class TooManyOutstandingQueries < InvalidRequest
    ERROR_CODE = 20210
  end

  class QueryTooComplex < InvalidRequest
    ERROR_CODE = 20211
  end

  class InvalidKeyRequest < InvalidRequest
    ERROR_CODE = 20212
  end

  class InvalidKey < InvalidRequest
    ERROR_CODE = 20213
  end

  class InvalidParameter < InvalidRequest
    ERROR_CODE = 20301
  end

  class UnableToSaveRecord < InvalidRequest
    ERROR_CODE = 20301
  end

  class MiscellaneousUpdateError < InvalidRequest
    ERROR_CODE = 20301
  end

  class WarningResponseNotGivenForAllWarnings < InvalidRequest
    ERROR_CODE = 20311
  end

  class WarningResponseGivenForWarningNotRequired < InvalidRequest
    ERROR_CODE = 20312
  end

  class InvalidResource < InvalidRequest
    ERROR_CODE = 20400
  end

  class InvalidType < InvalidRequest
    ERROR_CODE = 20401
  end

  class InvalidIdentifier < InvalidRequest
    ERROR_CODE = 20402
  end

  class UnsupportedMimeType < InvalidRequest
    ERROR_CODE = 20406
  end

  class UnauthorizedRetrieval < InvalidRequest
    ERROR_CODE = 20407
  end

  class ResourceUnavailable < InvalidRequest
    ERROR_CODE = 20408
  end

  class ObjectUnavailable < InvalidRequest
    ERROR_CODE = 20409
  end

  class RequestTooLarge < InvalidRequest
    ERROR_CODE = 20410
  end

  class ExecutionTimeout < InvalidRequest
    ERROR_CODE = 20411
  end

  class TooManyOutstandingRequests < InvalidRequest
    ERROR_CODE = 20412
  end

  class InvalidResourceRequested < InvalidRequest
    ERROR_CODE = 20500
  end

  class InvalidMetadataType < InvalidRequest
    ERROR_CODE = 20501
  end

  class InvalidIdentifierRequested < InvalidRequest
    ERROR_CODE = 20502
  end

  class NoMetadataFound < InvalidRequest
    ERROR_CODE = 20503
  end

  class UnsupportedMetadataMimeType < InvalidRequest
    ERROR_CODE = 20506
  end

  class UnauthorizedMetadataRetrieval < InvalidRequest
    ERROR_CODE = 20507
  end

  class MetadataResourceUnavailable < InvalidRequest
    ERROR_CODE = 20508
  end

  class MetadataUnavailable < InvalidRequest
    ERROR_CODE = 20509
  end

  class MetadataRequestTooLarge < InvalidRequest
    ERROR_CODE = 20510
  end

  class MetadataRequestTimeout < InvalidRequest
    ERROR_CODE = 20511
  end

  class TooManyOutstandingMetadataRequests < InvalidRequest
    ERROR_CODE = 20512
  end

  class RequestedDTDVersionUnavailable < InvalidRequest
    ERROR_CODE = 20514
  end

  class NotLoggedIn < InvalidRequest
    ERROR_CODE = 20701
  end
end

require 'rets/http_client'
require 'rets/client'
require 'rets/metadata'
require 'rets/parser/error_checker'
require 'rets/parser/compact'
require 'rets/parser/multipart'
require 'rets/measuring_http_client'
require 'rets/locking_http_client'
require 'rets/client_progress_reporter'
