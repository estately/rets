module Rets
  module Metadata
    class Resource
      class MissingRetsClass < RuntimeError; end
      attr_reader :id, :key_field, :rets_classes, :rets_objects

      def initialize(id, key_field, rets_classes, rets_objects)
        @id = id
        @key_field = key_field
        @rets_classes = rets_classes
        @rets_objects = rets_objects
      end

      def self.find_lookup_containers(metadata, resource_id)
        metadata[:lookup].select { |lc| lc.resource == resource_id }
      end

      def self.find_lookup_type_containers(metadata, resource_id, lookup_name)
        metadata[:lookup_type].select { |ltc| ltc.resource == resource_id && ltc.lookup == lookup_name }
      end

      def self.find_rets_classes(metadata, resource_id)
        class_container = metadata[:class].detect { |c| c.resource == resource_id }
        if class_container.nil?
          raise MissingRetsClass.new("No Metadata classes for #{resource_id}")
        else
          class_container.classes
        end
      end

      def self.find_rets_objects(metadata, resource_id)
        objects = metadata[:object]
        if objects
          objects.select { |object| object.resource == resource_id }.map(&:objects).flatten
        else
          []
        end
      end

      def self.build_lookup_tree(resource_id, metadata)
        lookup_types = Hash.new {|h, k| h[k] = Array.new }

        find_lookup_containers(metadata, resource_id).each do |lookup_container|
          lookup_container.lookups.each do |lookup_fragment|
            lookup_name = lookup_fragment["LookupName"]

            find_lookup_type_containers(metadata, resource_id, lookup_name).each do |lookup_type_container|
              lookup_type_container.lookup_types.each do |lookup_type_fragment|
                lookup_types[lookup_name] << LookupType.new(lookup_type_fragment)
              end
            end
          end
        end

        lookup_types
      end

      def self.build_classes(resource_id, lookup_types, metadata)
        find_rets_classes(metadata, resource_id).map do |rets_class_fragment|
          RetsClass.build(rets_class_fragment, resource_id, lookup_types, metadata)
        end
      end

      def self.build_objects(resource_id, metadata)
        find_rets_objects(metadata, resource_id).map do |rets_object_fragment|
          RetsObject.build(rets_object_fragment)
        end
      end

      def self.build(resource_fragment, metadata, logger)
        resource_id = resource_fragment["ResourceID"]
        key_field = resource_fragment["KeyField"]

        lookup_types = build_lookup_tree(resource_id, metadata)
        rets_classes = build_classes(resource_id, lookup_types, metadata)
        rets_objects = build_objects(resource_id, metadata)

        new(resource_id, key_field, rets_classes, rets_objects)
      rescue MissingRetsClass => e
        logger.warn(e.message)
        nil
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        out.puts "# Resource: #{id} (Key Field: #{key_field})"
        rets_classes.each do |rets_class|
          rets_class.print_tree(out)
        end
        rets_objects.each do |rets_object|
          rets_object.print_tree(out)
        end
      end

      def find_rets_class(rets_class_name)
        rets_classes.detect {|rc| rc.name == rets_class_name }
      end
    end
  end
end

