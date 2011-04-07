module Rets
  module Metadata
    TYPES = %w(SYSTEM RESOURCE CLASS TABLE LOOKUP LOOKUP_TYPE OBJECT)

    class Root
      attr_writer :types
      attr_accessor :tree
      attr_accessor :sources

      # fetcher is a proc that inverts control to the client
      # to retrieve metadata types
      def initialize(&fetcher)
        @tree = nil
        @types = nil # TODO think up a better name ... containers?
        @sources = nil

        return unless block_given?

        fetch_sources(&fetcher)
      end

      def fetch_sources(&fetcher)
        self.sources = Hash[*TYPES.map {|type| [type, fetcher.call(type)] }.flatten]
      end

      def dump
        Marshal.dump(sources)
      end

      def load(sources)
        self.sources = Marshal.load(sources)
      end

      def version
        types[:system].version
      end

      def date
        types[:system].date
      end

      def current?(current_timestamp, current_version)
        (current_version ? current_version == version : true) &&
          (current_timestamp ? current_timestamp == date : true)
      end

      def build_tree(metadata)
        return @tree if @tree

        tree = {}

        resource_containers = types[:resource]

        resource_containers.each do |resource_container|

          resource_container.resources.each do |resource_fragment|
            resource = Resource.build(resource_fragment, metadata)
            tree[resource.id] = resource
          end
        end

        @tree = tree
      end

      def types
        return @types if @types

        types = {}

        sources.each {|name, source| types[name] = build(Nokogiri.parse(source)) }

        @types = types
      end

      # Returns an array of container classes that represents
      # the metadata stored in the document provided.
      def build(doc)
        # find all tags that match /RETS/METADATA-*
        fragments = doc.xpath("/RETS/*[starts-with(name(), 'METADATA-')]")

        fragments.map do |fragment|
          build_container(fragment)
        end
      end

      def build_container(fragment)
        tag  = fragment.name             # METADATA-RESOURCE
        type = tag.sub(/^METADATA-/, "") # RESOURCE

        class_name = type.capitalize.gsub(/_(\w)/) { $1.upcase }
        container_name = "#{class_name}Container"

        container_class = Containers.constants.include?(container_name) ? Containers.const_get(container_name) : Containers::Container
        container_class.new(fragment)
      end

    end


    ######################################
    # OO representation and construction.
    #

    # Resource
    #  |
    # Class
    #  |
    #  `-- Table
    #  |
    #  `-- LookupTable
    #        |
    #        `-- LookupType
    #
    class Resource
      attr_accessor :rets_classes
      attr_accessor :lookup_types

      attr_accessor :id

      def initialize(resource)
        self.rets_classes = []
        self.lookup_types = {}

        self.id = resource["ResourceID"]
      end

      def self.find_lookup_containers(metadata, resource)
        metadata[:lookup].select { |lc| lc.resource == resource.id }
      end

      def self.find_lookup_type_containers(metadata, resource, lookup_name)
        metadata[:lookup_type].select { |ltc| ltc.resource == resource.id && ltc.lookup == lookup_name }
      end

      def self.find_rets_classes(metadata, resource)
        metadata[:class].detect { |c| c.resource == resource.id }.classes
      end

      def self.build_lookup_tree(resource, metadata)
        lookup_types = Hash.new {|h, k| h[k] = Array.new }

        find_lookup_containers(metadata, resource).each do |lookup_container|
          lookup_container.lookups.each do |lookup_fragment|
            lookup_name = lookup_fragment["LookupName"]

            find_lookup_type_containers(metadata, resource, lookup_name).each do |lookup_type_container|

              lookup_type_container.lookup_types.each do |lookup_type_fragment|
                lookup_types[lookup_name] << LookupType.new(lookup_type_fragment)
              end
            end
          end
        end

        lookup_types
      end

      def self.build_classes(resource, metadata)
        find_rets_classes(metadata, resource).map do |rets_class_fragment|
          RetsClass.build(rets_class_fragment, resource, metadata)
        end
      end

      def self.build(resource_fragment, metadata)
        resource = new(resource_fragment)

        resource.lookup_types = build_lookup_tree(resource, metadata)
        resource.rets_classes = build_classes(resource, metadata)
        resource
      end

      def print_tree
        puts "Resource: #{id}"

        rets_classes.each(&:print_tree)
      end

      def find_rets_class(rets_class_name)
        rets_classes.detect {|rc| rc.name == rets_class_name }
      end
    end

    class LookupType
      attr_accessor :long_value, :short_value, :value

      def initialize(lookup_type_fragment)
        self.value       = lookup_type_fragment["Value"]
        self.short_value = lookup_type_fragment["ShortValue"]
        self.long_value  = lookup_type_fragment["LongValue"]
      end

      def print_tree
        puts "      #{long_value} -> #{value}"
      end
    end

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

    class TableFactory
      def self.build(table_fragment, resource)
        enum?(table_fragment) ? LookupTable.new(table_fragment, resource) : Table.new(table_fragment)
      end

      def self.enum?(table_fragment)
        !table_fragment["LookupName"].strip.empty?
      end
    end

    class Table
      attr_accessor :type
      attr_accessor :name

      def initialize(table_fragment)
        self.type = table_fragment["DataType"]
        self.name = table_fragment["SystemName"]
      end

      def print_tree
        puts "    Table: #{name}"
      end

      def resolve(value)
        return [] if value.empty?

        [value]
      end
    end

    class LookupTable
      attr_accessor :resource
      attr_accessor :lookup_name
      attr_accessor :name
      attr_accessor :interpretation

      def initialize(table_fragment, resource)
        self.resource = resource
        self.name = table_fragment["SystemName"]
        self.interpretation = table_fragment["Interpretation"]
        self.lookup_name = table_fragment["LookupName"]
      end

      def multi?
        interpretation == "LookupMulti"
      end

      def lookup_types
        resource.lookup_types[lookup_name]
      end

      def print_tree
        puts "    LookupTable: #{name}"

        lookup_types.each(&:print_tree)
      end

      def lookup_type(value)
        lookup_types.detect {|lt| lt.value == value }
      end

      def resolve(value)
        return [] if value.empty?

        if multi?
          value.split(",").map {|v| lookup_type(v).long_value }
        else
          [lookup_type(value).long_value]
        end
      end
    end


    #########################
    # Basic representation of the underlying metadata. This models
    # the structure of RETS metadata closely. The OO-representation
    # uses this structure for its construction. External usage of
    # this API should be discouraged in favor of the richer OO
    # representation.
    #
    module Containers
      class Container
        attr_accessor :fragment

        def self.uses(*fields)
          fields.each do |field|
            define_method(field) do
              instance_variable_get("@#{field}") ||
                instance_variable_set("@#{field}", extract(fragment, field.to_s.capitalize))
            end
          end
        end

        uses :date, :version

        def initialize(fragment)
          self.fragment = fragment
        end

        def extract(fragment, attr)
          fragment.attr(attr)
        end

      end

      class RowContainer < Container

        attr_accessor :rows

        def initialize(doc)
          super

          self.rows = Parser::Compact.parse_document(doc).map do |row|
            Hash[*row.flatten]
          end
        end

      end

      class ResourceContainer < RowContainer
        alias resources rows
      end

      class ClassContainer < RowContainer
        uses :resource

        alias classes rows
      end

      class TableContainer < RowContainer
        uses :resource, :class

        alias tables rows
      end

      class LookupContainer < RowContainer
        uses :resource

        alias lookups rows
      end

      class LookupTypeContainer < RowContainer
        uses :resource, :lookup

        alias lookup_types rows
      end

      class ObjectContainer < RowContainer
        uses :resource

        alias objects rows
      end

      class SystemContainer < Container
      end
    end
  end
end

