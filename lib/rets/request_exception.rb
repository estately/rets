module Rets
  class RequestException < StandardError
    attr_accessor :response_code, :response_text
    def initialize(response_code, response_text)
      @response_code = response_code
      @response_text = response_text
    end

    def message
      "Got error code #{response_code} (#{response_text})."
    end
  end
end
