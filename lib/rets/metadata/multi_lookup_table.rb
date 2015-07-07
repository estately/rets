module Rets
  module Metadata
    class MultiLookupTable
      attr_reader :lookup_table

      def initialize(table_fragment, lookup_types, resource_id)
        @lookup_table = LookupTable.new(table_fragment, lookup_types, resource_id)
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        lookup_table.print_tree(out)
      end

      def resolve(value)
        if value.empty?
          []
        else
          value.split(",").map do |v|
            lookup_table.resolve(v)
          end
        end
      end

    end
  end
end
