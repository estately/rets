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

        if Containers::ROW_CONTAINER_TYPES.include?(class_name)
          Containers::RowContainer.new(fragment)
        else
          Containers::Container.new(fragment)
        end
      end
    end
  end
end
