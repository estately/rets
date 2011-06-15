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

        self.columns = doc.at("//COLUMNS").text
        rows = doc.xpath("//DATA")

        rows.map.with_index do |data, i|
          puts "## Processing record: #{i+1} (#{Time.now})" if i%500 == 0
          parse(data.text, delimiter)
        end
      end

      def self.columns=(columns, delimiter = TAB)
        @columns = columns.split(delimiter)
      end

      def self.columns
        @columns
      end

      def self.parse_count(xml)
        Nokogiri.parse(xml).at("//COUNT").attribute("Records").value.to_i
      end

      # Parses a single row of RETS-COMPACT data.
      #
      # Delimiter must be a regexp because String#split behaves differently when
      # given a string pattern. (It removes leading spaces).
      #
      def self.parse(data, delimiter = TAB)
        raise ArgumentError, "Delimiter must be a regular expression" unless Regexp === delimiter

        hash = {}
        data.split(delimiter, INCLUDE_NULL_FIELDS).each_with_index { |v, i| hash[columns[i]] = v.to_s unless v.to_s.empty? }
        hash
      end
    end
  end
end
