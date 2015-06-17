module Rets
  module Parser
    class ErrorChecker
      INVALID_REQUEST_ERROR_MAPPING = Hash[Rets.constants.map {|c| Rets.const_get(c) }.select { |klass| klass.is_a?(Class) && klass < Rets::InvalidRequest }.map {|klass| [klass.const_get('ERROR_CODE'), klass] }]

      def self.check(response)
        # some RETS servers returns HTTP code 412 when session cookie expired, yet the response body
        # passes XML check. We need to special case for this situation.
        # This method is also called from multipart.rb where there are headers and body but no status_code
        if response.respond_to?(:status_code) && response.status_code == 412
          raise HttpError, "HTTP status: #{response.status_code}, body: #{response.body}"
        end

        # some RETS servers return success code in XML body but failure code 4xx in http status
        # If xml body is present we ignore http status

        if !response.body.empty?
          begin
            xml = Nokogiri::XML.parse(response.body, nil, nil, Nokogiri::XML::ParseOptions::STRICT)

            rets_element = xml.xpath("/RETS")
            unless rets_element.empty?
              reply_text = (rets_element.attr("ReplyText") || rets_element.attr("replyText")).value
              reply_code = (rets_element.attr("ReplyCode") || rets_element.attr("replyCode")).value.to_i

              if reply_code == NoRecordsFound::ERROR_CODE
                raise NoRecordsFound.new(reply_text)
              elsif reply_code == NoObjectFound::ERROR_CODE
                raise NoObjectFound.new(reply_text)
              elsif reply_code.nonzero?
                error_class = INVALID_REQUEST_ERROR_MAPPING[reply_code]
                if error_class
                  raise error_class.new(reply_code, reply_text)
                else
                  raise InvalidRequest.new(reply_code, reply_text)
                end
              else
                return
              end
            end
          rescue Nokogiri::XML::SyntaxError
            #Not xml
          end
        end

        if response.respond_to?(:ok?) && ! response.ok?
          if response.status_code == 401
            raise AuthorizationFailure.new(response.status_code, response.body)
          else
            raise HttpError, "HTTP status: #{response.status_code}, body: #{response.body}"
          end
        end
      end
    end
  end
end
