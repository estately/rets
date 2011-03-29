module Rets
  module Metadata
    class Container
      attr_accessor :doc, :date, :version

      def initialize(doc)
        self.doc     = doc

        self.date    = extract_date(doc)
        self.version = extract_version(doc)
      end

      def extract_date(doc)
        doc.at("/RETS/#{tag}").attr("Date")
      end

      def extract_version(doc)
        doc.at("/RETS/#{tag}").attr("Version")
      end

      def tag
        doc.at("/RETS/*").name
      end
    end

    class RowContainer < Container

      attr_accessor :rows

      def initialize(doc)
        super

        columns = doc.at("/RETS/#{tag}/COLUMNS").text
        datas   = doc.xpath("/RETS/#{tag}/DATA")

        self.rows = datas.map do |data|
          Hash[*Parser::Compact.parse(columns, data.text).flatten]
        end
      end

      # Delegate to rows.

      def size
        rows.size
      end

      include Enumerable

      def each(&block)
        rows.each(&block)
      end
    end

    class ResourceContainer < RowContainer
    end

    class ClassContainer < RowContainer
    end

    class TableContainer < RowContainer
    end

    class LookupContainer < RowContainer
    end

    class LookupTypeContainer < RowContainer
    end

    class ObjectContainer < RowContainer
    end

    class SystemContainer < Container
    end


    # Returns an array of classes representing the underlying metadata.
    def self.build(doc)
      # ... type could be RESOURCE or LOOKUP_TYPE ... :(
      tag  = doc.at("/RETS/*").name   # METADATA-RESOURCE
      type = tag.sub(/^METADATA-/, "") # RESOURCE

      class_name = type.capitalize.gsub(/_(\w)/) { $1.upcase }
      container_name = "#{class_name}Container"

      container_class = constants.include?(container_name) ? const_get(container_name) : Container
      container_class.new(doc)
    end

  end
end

