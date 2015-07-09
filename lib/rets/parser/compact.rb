module Rets
  module Parser
    class Compact
      TAB = /\t/

      InvalidDelimiter = Class.new(ArgumentError)

      def self.parse_document(xml)
        doc = Nokogiri.parse(xml.to_s)

        delimiter = doc.at("//DELIMITER")
        if delimiter
          value = delimiter.attr(:value) || delimiter.attr("Value")
          delimiter = Regexp.new(Regexp.escape(value.to_i.chr))
        else
          delimiter = TAB
        end

        if delimiter == // || delimiter == /,/
          raise InvalidDelimiter, "Empty or invalid delimiter found, unable to parse."
        end

        column_node  = doc.at("//COLUMNS")
        column_names = column_node.nil? ? [] : column_node.text.split(delimiter)

        rows = doc.xpath("//DATA")
        rows.map do |data|
          self.parse_row(column_names, data.text, delimiter)
        end
      end

      # Parses a single row of RETS-COMPACT data.
      #
      # Delimiter must be a regexp because String#split behaves differently when
      # given a string pattern. (It removes leading spaces).
      #
      def self.parse_row(column_names, data, delimiter = TAB)
        raise ArgumentError, "Delimiter must be a regular expression" unless Regexp === delimiter

        data_values = data.split(delimiter).map { |x| CGI.unescapeHTML(x) }

        zipped_key_values = column_names.zip(data_values).map { |k, v| [k.freeze, v.to_s] }

        hash = Hash[*zipped_key_values.flatten]
        hash.reject { |key, value| key.empty? && value.to_s.empty? }
      end

      def self.get_count(xml)
        doc = Nokogiri.parse(xml.to_s)
        if node = doc.at("//COUNT")
          return node.attr('Records').to_i
        elsif node = doc.at("//RETS-STATUS")
          # Handle <RETS-STATUS ReplyCode="20201" ReplyText="No matching records were found" />
          return 0 if node.attr('ReplyCode') == '20201'
        end
      end

    end
  end
end
