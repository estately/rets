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
            rets_class.tables << TableFactory.build(table_fragment, resource)
          end
        end

        rets_class
      end

      def print_tree
        puts "  Class: #{name}"
        puts "    Visible Name: #{visible_name}"
        puts "    Description : #{description}"
        tables.each(&:print_tree)
      end

      def find_table(name)
        tables.detect { |value| value.name == name }
      end
    end
  end
end
