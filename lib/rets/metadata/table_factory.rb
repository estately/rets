module Rets
  module Metadata
    class TableFactory
      def self.build(table_fragment, resource_id)

        if table_fragment['LookupName'].strip.empty?
          Table.new(table_fragment, resource_id)
        elsif table_fragment["Interpretation"] == 'LookupMulti'
          MultiLookupTable.new(table_fragment, resource_id)
        elsif table_fragment["Interpretation"] =~ /Lookup/
          LookupTable.new(table_fragment, resource_id)
        else
          Table.new(table_fragment, resource_id)
        end
      end
    end
  end
end
