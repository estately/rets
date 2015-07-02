module Rets
  module Metadata
    class RetsClass
      attr_accessor :tables
      attr_accessor :name
      attr_accessor :visible_name
      attr_accessor :description
      attr_accessor :resource

      def initialize(rets_class_fragment, resource)
        self.resource = resource
        self.tables = []
        self.name = rets_class_fragment["ClassName"]
        self.visible_name = rets_class_fragment["VisibleName"]
        self.description = rets_class_fragment["Description"]
      end

      def self.find_table_container(metadata, resource, rets_class)
        metadata[:table].detect { |t| t.resource == resource.id && t.class == rets_class.name }
      end

      def self.build(rets_class_fragment, resource, metadata)
        rets_class = new(rets_class_fragment, resource)

        table_container = find_table_container(metadata, resource, rets_class)

        if table_container
          table_container.tables.each do |table_fragment|
            rets_class.tables << TableFactory.build(table_fragment, resource.id)
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
