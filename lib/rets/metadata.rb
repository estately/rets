module Rets
  module Metadata
    class Container
      attr_accessor :date, :version, :rows

      def initialize(date, version)
        self.rows = []
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

    # Returns an array of classes representing the underlying metadata.
    def self.build(doc)
      # ... type could be RESOURCE or LOOKUP_TYPE ... :(
      tag  = doc.at("/RETS/*").name   # METADATA-RESOURCE
      type = tag.sub(/^METADATA-/, "") # RESOURCE

      # instantiate type, and pass doc in?

      columns = doc.at("/RETS/#{tag}/COLUMNS").text
      datas   = doc.xpath("/RETS/#{tag}/DATA")

      # TODO: check constant exists first
      klass   = const_get(type.capitalize.gsub(/_(\w)/) { $1.upcase } )

      date    = doc.at("/RETS/#{tag}").attr("Date")
      version = doc.at("/RETS/#{tag}").attr("Version")

      container = Container.new(date, version)

      # Returns array of Resources, or LookupTypes etc.
      datas.each do |data|
        container.rows << klass.new(columns, data.text)
      end

      container
    end

    class Base

      def initialize(columns, data)
        @key_values = nil

        parse!(columns, data)
      end

      def parse!(columns, data)
        @key_values = Hash[*Parser::Compact.parse(columns, data).flatten]
      end

      def [](x)
        @key_values[x]
      end
    end

    class Resource < Base
    end

    class Class < Base
    end

    class System < Base
    end

    class Unknown < Base
    end
  end
end

