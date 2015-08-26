module Rets
  module Metadata
    class LookupTable
      attr_reader :resource_id, :lookup_types, :table_fragment, :name, :long_name

      def initialize(resource_id, lookup_types, table_fragment)
        @resource_id = resource_id
        @lookup_types = lookup_types

        @table_fragment = table_fragment
        @name = table_fragment["SystemName"]
        @long_name = table_fragment["LongName"]
      end

      def self.build(table_fragment, resource_id, lookup_types)
        lookup_name = table_fragment["LookupName"]
        lookup_types = lookup_types[lookup_name]
        new(resource_id, lookup_types, table_fragment)
      end

      def multi?
        table_fragment["Interpretation"] == "LookupMulti"
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        out.puts "    LookupTable: #{name}"
        out.puts "      Resource: #{resource_id}"
        out.puts "      Required: #{table_fragment['Required']}"
        out.puts "      Searchable: #{ table_fragment["Searchable"] }"
        out.puts "      Units: #{ table_fragment["Units"] }"
        out.puts "      ShortName: #{ table_fragment["ShortName"] }"
        out.puts "      LongName: #{ long_name }"
        out.puts "      StandardName: #{ table_fragment["StandardName"] }"
        out.puts "      Types:"

        lookup_types.each do |lookup_type|
          lookup_type.print_tree(out)
        end
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

          resolved_value = lookup_type ? lookup_type.long_value : clean_value

          warn("Discarding unmappable value of #{clean_value.inspect}") if resolved_value.nil? && $VERBOSE

          resolved_value
        end

        multi? ? values.map {|v| v.to_s.strip } : values.first.to_s.strip
      end
    end
  end
end
