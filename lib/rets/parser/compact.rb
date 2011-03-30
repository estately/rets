module Rets
  module Parser
    class Compact
      TAB = 9.chr

      InvalidDelimiter = Class.new(ArgumentError)

      def self.parse_document(xml)
        doc = Nokogiri.parse(xml.to_s)

        delimiter = doc.at("//DELIMITER")
        delimiter = delimiter ? delimiter.attr(:value).to_i.chr : TAB

        if delimiter.empty? || delimiter == ","
          raise InvalidDelimiter, "Empty or invalid delimiter found, unable to parse."
        end

        columns = doc.at("//COLUMNS").text.lstrip
        rows    = doc.xpath("//DATA")

        rows.map do |data|
          self.parse(columns, data.text.lstrip, delimiter)
        end
      end

      def self.parse(columns, data, delimiter = TAB)
        column_names = columns.split(delimiter)
        column_names.zip(data.split(delimiter))
      end
    end
  end
end
