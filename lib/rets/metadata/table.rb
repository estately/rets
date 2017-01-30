module Rets
  module Metadata
    class Table
      attr_reader :table_fragment, :resource_id, :name, :long_name

      def initialize(table_fragment, resource_id)
        @table_fragment = table_fragment
        @resource_id = resource_id

        @name = table_fragment["SystemName"]
        @long_name = table_fragment["LongName"]
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        out.puts "### Table: #{name}"
        out.puts "      Resource: #{resource_id}"
        out.puts "      ShortName: #{ table_fragment["ShortName"] }"
        out.puts "      LongName: #{ long_name }"
        out.puts "      StandardName: #{ table_fragment["StandardName"] }"
        out.puts "      Units: #{ table_fragment["Units"] }"
        out.puts "      Searchable: #{ table_fragment["Searchable"] }"
        out.puts "      Required: #{table_fragment['Required']}"
      end

      def resolve(value)
        value.to_s.strip
      end
    end
  end
end
