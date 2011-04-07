module Rets
  module Metadata
    class RetsClass
      attr_accessor :tables
      attr_accessor :name
      attr_accessor :resource

      def initialize(rets_class_fragment, resource)
        self.resource = resource
        self.tables = []
        self.name = rets_class_fragment["ClassName"]
      end

      def self.find_table_container(metadata, resource, rets_class)
        metadata[:table].detect { |t| t.resource == resource.id && t.class == rets_class.name }
      end

      def self.build(rets_class_fragment, resource, metadata)
        rets_class = new(rets_class_fragment, resource)

        find_table_container(metadata, resource, rets_class).tables.each do |table_fragment|
          rets_class.tables << TableFactory.build(table_fragment, resource)
        end

        rets_class
      end

      def print_tree
        puts "  Class: #{name}"
        tables.each(&:print_tree)
      end

      def find_table(name)
        tables.detect { |value| value.name == name }
      end
    end
  end
end
