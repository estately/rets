module Rets
  module Metadata
    class MultiLookupTable
      attr_reader :table_fragment, :resource_id, :name, :lookup_name, :long_name

      def initialize(table_fragment, resource_id)
        @table_fragment = table_fragment

        @resource_id = resource_id

        @name = table_fragment["SystemName"]
        @lookup_name = table_fragment["LookupName"]
        @long_name = table_fragment["LongName"]
      end

      def lookup_types
        resource.lookup_types[lookup_name]
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        out.puts "    LookupTable: #{name}"
        out.puts "      Resource: #{resource.id}"
        out.puts "      Required: #{table_fragment['Required']}"
        out.puts "      Searchable: #{ table_fragment["Searchable"] }"
        out.puts "      Units: #{ table_fragment["Units"] }"
        out.puts "      ShortName: #{ table_fragment["ShortName"] }"
        out.puts "      LongName: #{ table_fragment["LongName"] }"
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
          return []
        end

         value.split(",").map do |v|

          #Remove surrounding quotes
          clean_value  = v.scan(/^["']?(.*?)["']?$/).join


          lookup_type = lookup_type(clean_value)

          resolved_value = lookup_type ? lookup_type.long_value : nil

          warn("Discarding unmappable value of #{clean_value.inspect}") if resolved_value.nil? && $VERBOSE

          resolved_value.to_s.strip
        end
      end
    end
  end
end
