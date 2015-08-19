module Rets
  module Metadata
    class TableFactory

      def self.build(table_fragment, resource_id, lookup_types)
        if table_fragment["LookupName"].empty?
          Table.new(table_fragment, resource_id)
        else
          if table_fragment["Interpretation"] == "LookupMulti"
            MultiLookupTable.build(table_fragment, resource_id, lookup_types)
          else
            LookupTable.build(table_fragment, resource_id, lookup_types)
          end
        end
      end

    end
  end
end
