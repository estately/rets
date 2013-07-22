require 'uri'
require 'digest/md5'
require 'nokogiri'

module Rets
  VERSION = '0.4.0'

  AuthorizationFailure = Class.new(ArgumentError)
  InvalidRequest       = Class.new(ArgumentError)
  MalformedResponse    = Class.new(ArgumentError)
  UnknownResponse      = Class.new(ArgumentError)
  NoLogout             = Class.new(ArgumentError)
end

require 'rets/client'
require 'rets/metadata'
require 'rets/parser/compact'
require 'rets/parser/multipart'
require 'rets/measuring_http_client'
require 'rets/locking_http_client'
require 'rets/client_progress_reporter'
