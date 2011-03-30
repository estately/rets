module Rets
  module Parser

    # Inspired by Mail.
    class Multipart
      CRLF = "\r\n"
      WSP  = "\s"

      HEADER_LINE = /^([!-9;-~]+:\s*.+)$/

      Part = Struct.new(:headers, :body)

      def self.parse(raw, boundary)
        parts = []

        boundary_regexp = /--#{Regexp.quote(boundary)}(--)?#{CRLF}/

          raw.split(boundary_regexp).each do |chunk|

          header_part, body_part = chunk.split(/#{CRLF}#{WSP}*#{CRLF}/m, 2)

            if header_part =~ HEADER_LINE
              headers = header_part.split(/\r\n/).map { |kv| k,v = kv.split(/:\s?/); [k.downcase, v] }
              headers = Hash[*headers.flatten]

              parts << Part.new(headers, body_part)
            else
              next # not a valid chunk.
            end
          end

        parts
      end
    end
  end
end
