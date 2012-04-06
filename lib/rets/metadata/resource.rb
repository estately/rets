module Rets
  module Metadata
    class Resource
      attr_accessor :rets_classes
      attr_accessor :lookup_types
      attr_accessor :key_field

      attr_accessor :id

      def initialize(resource)
        self.rets_classes = []
        self.lookup_types = {}

        self.id = resource["ResourceID"]
        self.key_field = resource["KeyField"]
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
  end
end

