require 'net/http'
require 'uri'
require 'cgi'
require 'digest/md5'

require 'rubygems'
require 'net/http/persistent'
require 'nokogiri'

module Rets
  VERSION = '0.1.4'

  AuthorizationFailure = Class.new(ArgumentError)
  InvalidRequest       = Class.new(ArgumentError)
  MalformedResponse    = Class.new(ArgumentError)
  UnknownResponse      = Class.new(ArgumentError)
end

require 'rets/authentication'
require 'rets/metadata'
require 'rets/parser/compact'
require 'rets/parser/multipart'

require 'rets/client'
