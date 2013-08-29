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
      attr_accessor :long_name
      attr_accessor :table_fragment

      def initialize(table_fragment)
        self.table_fragment = table_fragment
        self.type = table_fragment["DataType"]
        self.name = table_fragment["SystemName"]
        self.long_name = table_fragment["LongName"]
      end

      def print_tree
        puts "    Table: #{name}"
        puts "      ShortName: #{ table_fragment["ShortName"] }"
        puts "      LongName: #{ table_fragment["LongName"] }"
        puts "      StandardName: #{ table_fragment["StandardName"] }"
        puts "      Units: #{ table_fragment["Units"] }"
        puts "      Searchable: #{ table_fragment["Searchable"] }"
      end

      def resolve(value)
        value.to_s.strip
      end
    end

    class LookupTable
      attr_accessor :resource
      attr_accessor :lookup_name
      attr_accessor :name
      attr_accessor :interpretation
      attr_accessor :long_name
      attr_accessor :table_fragment

      def initialize(table_fragment, resource)
        self.table_fragment = table_fragment
        self.resource = resource
        self.name = table_fragment["SystemName"]
        self.interpretation = table_fragment["Interpretation"]
        self.lookup_name = table_fragment["LookupName"]
        self.long_name = table_fragment["LongName"]
      end

      def multi?
        interpretation == "LookupMulti"
      end

      def lookup_types
        resource.lookup_types[lookup_name]
      end

      def print_tree
        puts "    LookupTable: #{name}"
        puts "      LongName: #{long_name}"
        puts "      LookupName: #{lookup_name}"
        puts "      Lookup Values:"
        lookup_types.each(&:print_tree)
      end

      def lookup_type(value)
        lookup_types.detect {|lt| lt.value == value }
      end

      def resolve(value)
        if value.empty?
          return [] if multi?
          return value.to_s.strip
        end

        values = multi? ? value.split(","): [value]

        values = values.map do |v|

          #Remove surrounding quotes
          clean_value  = v.scan(/^["']?(.*?)["']?$/).join


          lookup_type = lookup_type(clean_value)

          resolved_value = lookup_type ? lookup_type.long_value : nil

          warn("Discarding unmappable value of #{clean_value.inspect}") if resolved_value.nil? && $VERBOSE

          resolved_value
        end

        multi? ? values.map {|v| v.to_s.strip } : values.first.to_s.strip
      end
    end
  end
end
