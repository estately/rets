module Rets
  module Parser
    class Capabilities
      CASE_INSENSITIVE_PROC = Proc.new { |h,k| h.key?(k.downcase) ? h[k.downcase] : nil }

      attr_reader :document

      def self.extract(response_body)
        new(response_body).capabilities
      end

      def initialize(response_body)
        @response_body = response_body
      end

      def capabilities
        hash = raw_key_values.split(/\n/).
          map  { |r| r.split(/\=/, 2) }.
          each_with_object({}) { |(k,v), h| h[k.strip.downcase] = v.strip }

        add_case_insensitive_default_proc(hash)
      end

      private

      def document
        @document ||= Nokogiri.parse(response_body)
      end

      def raw_key_values
        document.xpath("/RETS/RETS-RESPONSE").text.strip
      end

      def add_case_insensitive_default_proc(hash)
        new_hash = hash.dup
        new_hash.default_proc = CASE_INSENSITIVE_PROC
        new_hash
      end
    end
  end
end
