module Rets
  module Parser
    class Compact
      TAB = /\t/

      INCLUDE_NULL_FIELDS = -1

      InvalidDelimiter = Class.new(ArgumentError)

      def self.parse_document(xml)
        doc = Nokogiri.parse(xml.to_s)

        delimiter = doc.at("//DELIMITER")
        delimiter = delimiter ? Regexp.new(Regexp.escape(delimiter.attr(:value).to_i.chr)) : TAB

        if delimiter == // || delimiter == /,/
          raise InvalidDelimiter, "Empty or invalid delimiter found, unable to parse."
        end

        column_node = doc.at("//COLUMNS")
        if column_node.nil?
          columns = ''
        else
          columns = column_node.text
        end
        rows    = doc.xpath("//DATA")

        rows.map do |data|
          self.parse(columns, data.text, delimiter)
        end
      end

      # Parses a single row of RETS-COMPACT data.
      #
      # Delimiter must be a regexp because String#split behaves differently when
      # given a string pattern. (It removes leading spaces).
      #
      def self.parse(columns, data, delimiter = TAB)
        raise ArgumentError, "Delimiter must be a regular expression" unless Regexp === delimiter

        column_names = columns.split(delimiter)
        data_values = data.split(delimiter, INCLUDE_NULL_FIELDS)

        zipped_key_values = column_names.zip(data_values).map { |k, v| [k, v.to_s] }

        hash = Hash[*zipped_key_values.flatten]
        hash.reject { |key, value| key.empty? && value.to_s.empty? }
      end
    end
  end
end
