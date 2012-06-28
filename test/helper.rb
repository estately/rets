require "test/unit"
require "mocha"

require "rets"

require "fixtures"

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr_cassettes'
  c.hook_into :webmock
end

