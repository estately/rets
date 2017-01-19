module Rets
  module Metadata
    class RetsClass
      attr_reader :name, :visible_name, :standard_name, :description, :tables

      def initialize(name, visible_name, standard_name, description, tables)
        @name = name
        @visible_name = visible_name
        @description = description
        @standard_name = standard_name

        @tables = tables
      end

      def self.find_table_container(metadata, resource_id, class_name)
        metadata[:table].detect { |t| t.resource == resource_id && t.class == class_name }
      end

      def self.builds_tables(table_container, resource_id, lookup_types)
        if table_container
          table_container.tables.map do |table_fragment|
            TableFactory.build(table_fragment, resource_id, lookup_types)
          end
        else
          []
        end
      end

      def self.build(rets_class_fragment, resource_id, lookup_types, metadata)
        class_name = rets_class_fragment["ClassName"]
        visible_name = rets_class_fragment["VisibleName"]
        standard_name = rets_class_fragment["StandardName"]
        description = rets_class_fragment["Description"]

        table_container = find_table_container(metadata, resource_id, class_name)
        tables = builds_tables(table_container, resource_id, lookup_types)
        new(class_name, visible_name, standard_name, description, tables)
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        out.puts "## Class: #{name}"
        out.puts "    Visible Name: #{visible_name}"
        out.puts "    Description : #{description}"
        tables.each do |table|
          table.print_tree(out)
        end
      end

      def find_table(name)
        tables.detect { |value| value.name.downcase == name.downcase }
      end
    end
  end
end
