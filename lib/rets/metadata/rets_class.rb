module Rets
  module Metadata
    class RetsClass
      attr_accessor :tables
      attr_accessor :name
      attr_accessor :visible_name
      attr_accessor :description

      def initialize(rets_class_fragment)
        self.tables = []
        self.name = rets_class_fragment["ClassName"]
        self.visible_name = rets_class_fragment["VisibleName"]
        self.description = rets_class_fragment["Description"]
      end

      def self.find_table_container(metadata, resource_id, rets_class)
        metadata[:table].detect { |t| t.resource == resource_id && t.class == rets_class.name }
      end

      def self.build(rets_class_fragment, resource_id, lookup_types, metadata)
        rets_class = new(rets_class_fragment)

        table_container = find_table_container(metadata, resource_id, rets_class)

        if table_container
          table_container.tables.each do |table_fragment|
            rets_class.tables << TableFactory.build(table_fragment, resource_id, lookup_types)
          end
        end

        rets_class
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        out.puts "  Class: #{name}"
        out.puts "    Visible Name: #{visible_name}"
        out.puts "    Description : #{description}"
        tables.each do |table|
          table.print_tree(out)
        end
      end

      def find_table(name)
        tables.detect { |value| value.name == name }
      end
    end
  end
end
