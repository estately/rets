module Rets
  module Metadata
    class TableFactory
      def self.build(table_fragment, resource_id)
        if lookup_table?(table_fragment)
          if multi_lookup_table?(table_fragment)
            MultiLookupTable.new(table_fragment, resource_id)
          else
            LookupTable.new(table_fragment, resource_id)
          end
        else
          Table.new(table_fragment, resource_id)
        end
      end

      def self.lookup_table?(table_fragment)
        lookup_value   = table_fragment["LookupName"].strip
        interpretation = table_fragment["Interpretation"].strip

        interpretation =~ /Lookup/ && !lookup_value.empty?
      end

      def self.multi_lookup_table?(table_fragment)
        interpretation = table_fragment["Interpretation"]

        interpretation == "LookupMulti"
      end
    end
  end
end
