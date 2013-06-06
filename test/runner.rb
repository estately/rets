require 'minitest/autorun'
$:.unshift(File.expand_path('../lib', __FILE__))
require_relative 'helper'

require_relative 'test_client'
require_relative 'test_metadata'
require_relative 'test_parser_compact'
require_relative 'test_parser_multipart'
