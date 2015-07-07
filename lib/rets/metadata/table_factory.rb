module Rets
  module Metadata
    class TableFactory
      def self.build(table_fragment, resource)
        if enum?(table_fragment)
          LookupTable.build(table_fragment, resource)
        else
          Table.new(table_fragment, resource.id)
        end
      end

      def self.enum?(table_fragment)
        lookup_value   = table_fragment["LookupName"].strip
        interpretation = table_fragment["Interpretation"].strip

        interpretation =~ /Lookup/ && !lookup_value.empty?
      end
    end
  end
end
