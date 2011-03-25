require 'net/http'
require 'uri'
require 'cgi'
require 'digest/md5'

require 'rubygems'
require 'net/http/persistent'
require 'nokogiri'

module Rets
  VERSION = '0.0.1'

  AuthorizationFailure = Class.new(ArgumentError)
  InvalidRequest       = Class.new(ArgumentError)
  MalformedResponse    = Class.new(ArgumentError)
end

require 'rets/authentication'
require 'rets/client'
