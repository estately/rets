module Rets
  module Metadata
    class TableFactory
      def self.build(table_fragment, resource)
        enum?(table_fragment) ? LookupTable.new(table_fragment, resource) : Table.new(table_fragment)
      end

      def self.enum?(table_fragment)
        lookup_value   = table_fragment["LookupName"].strip
        interpretation = table_fragment["Interpretation"].strip

        interpretation =~ /Lookup/ && !lookup_value.empty?
      end
    end

    class Table
      attr_accessor :type
      attr_accessor :name

      def initialize(table_fragment)
        self.type = table_fragment["DataType"]
        self.name = table_fragment["SystemName"]
      end

      def print_tree
        puts "    Table: #{name}"
      end

      def resolve(value)
        return [] if value.empty?

        [value]
      end
    end

    class LookupTable
      attr_accessor :resource
      attr_accessor :lookup_name
      attr_accessor :name
      attr_accessor :interpretation

      def initialize(table_fragment, resource)
        self.resource = resource
        self.name = table_fragment["SystemName"]
        self.interpretation = table_fragment["Interpretation"]
        self.lookup_name = table_fragment["LookupName"]
      end

      def multi?
        interpretation == "LookupMulti"
      end

      def lookup_types
        resource.lookup_types[lookup_name]
      end

      def print_tree
        puts "    LookupTable: #{name}"

        lookup_types.each(&:print_tree)
      end

      def lookup_type(value)
        lookup_types.detect {|lt| lt.value == value }
      end

      def resolve(value)
        return [] if value.empty?

        if multi?
          value.split(",").map {|v| lookup_type(v).long_value }
        else
          [lookup_type(value).long_value]
        end
      end
    end
  end
end
