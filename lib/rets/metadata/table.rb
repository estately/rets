module Rets
  module Metadata
    class Table
      attr_accessor :type
      attr_accessor :name
      attr_accessor :long_name
      attr_accessor :table_fragment
      attr_accessor :resource

      def initialize(table_fragment, resource)
        self.table_fragment = table_fragment
        self.resource = resource
        self.type = table_fragment["DataType"]
        self.name = table_fragment["SystemName"]
        self.long_name = table_fragment["LongName"]
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        out.puts "    Table: #{name}"
        out.puts "      Resource: #{resource.id}"
        out.puts "      ShortName: #{ table_fragment["ShortName"] }"
        out.puts "      LongName: #{ table_fragment["LongName"] }"
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
