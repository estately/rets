module Rets
  module Metadata
    METADATA_TYPES = %w(SYSTEM RESOURCE CLASS TABLE LOOKUP LOOKUP_TYPE OBJECT)

    # It's useful when dealing with the Rets standard to represent their
    # relatively flat namespace of interweived components as a Tree. With
    # a collection of resources at the top, and their various, classes,
    # tables, lookups, and lookup types underneath.
    #
    # It looks something like ...
    #
    #    Resource
    #     |
    #    Class
    #     |
    #     `-- Table
    #     |
    #     `-- Lookups
    #           |
    #           `-- LookupType
    #
    # For our purposes it was helpful to denormalize some of the more deeply
    # nested branches. In particular by relating Lookups to LookupTypes, and
    # Tables to lookups with can simplify this diagram.
    #
    #
    #    Resource
    #     |
    #    Class
    #     |
    #     `-- Table
    #          |
    #          `-- Lookups
    #
    # By associating Tables and lookups when we parse this structure. It allows
    # us to seemlessly map Lookup values to their Long or Short value forms.
    class Root
      # Metadata_types is the low level parsed representation of the raw xml
      # sources. Just one level up, they contain Containers, consisting of
      # SystemContainers or RowContainers
      attr_writer :metadata_types

      # the tree is the high level represenation of the metadata heiarchy
      # it begins with root. Stored as a list of Metadata::Resources
      attr_writer :tree

      # Sources are the raw xml documents fetched for each metadata type
      # they are stored as a hash with the type names as their keys
      # and the raw xml as the values
      attr_reader :sources

      # Metadata can be unmarshalled from cache. @logger is not set during that process, constructor is not called.
      # Client code must set it after unmarshalling.
      attr_reader :logger

      # fetcher is a proc that inverts control to the client to retrieve metadata
      # types
      def initialize(logger, sources)
        @logger = logger
        @tree = nil
        @metadata_types = nil # TODO think up a better name ... containers?
        @sources = sources
      end

      def marshal_dump
        sources
      end

      def version
        metadata_types[:system].first.version
      end

      def date
        metadata_types[:system].first.date
      end

      # Wether there exists a more up to date version of the metadata to fetch
      # is dependant on either a timestamp indicating when the most recent
      # version was published, or a version number. These values may or may
      # not exist on any given rets server.
      def current?(current_timestamp, current_version)
        if !current_version.to_s.empty? && !version.to_s.empty?
          current_version == version
        else
          current_timestamp ? current_timestamp == date : true
        end
      end

      def build_tree
        tree = Hash.new { |h, k| h.key?(k.downcase) ? h[k.downcase] : nil }

        resource_containers = metadata_types[:resource]

        resource_containers.each do |resource_container|
          resource_container.rows.each do |resource_fragment|
            resource = Resource.build(resource_fragment, metadata_types, @logger)
            #some mlses list resource types without an associated data, throw those away
            tree[resource.id.downcase] = resource if resource
          end
        end

        tree
      end

      def tree
        @tree ||= build_tree
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        tree.each do |name, value|
          value.print_tree(out)
        end
      end

      def metadata_types
        return @metadata_types if @metadata_types

        h = {}

        sources.each do |name, source|
          h[name.downcase.to_sym] = build_containers(Nokogiri.parse(source))
        end

        @metadata_types = h
      end

      # Returns an array of container classes that represents
      # the metadata stored in the document provided.
      def build_containers(doc)
        # find all tags that match /RETS/METADATA-*
        fragments = doc.xpath("/RETS/*[starts-with(name(), 'METADATA-')]")

        fragments.map { |fragment| build_container(fragment) }
      end

      def build_container(fragment)
        tag  = fragment.name             # METADATA-RESOURCE
        type = tag.sub(/^METADATA-/, "") # RESOURCE

        class_name = type.capitalize.gsub(/_(\w)/) { $1.upcase }
        container_name = "#{class_name}Container"

        if ::RUBY_VERSION < '1.9'
          container_class = Containers.const_defined?(container_name) ? Containers.const_get(container_name) : Containers::Container
        else
          container_class = Containers.const_defined?(container_name, true) ? Containers.const_get(container_name, true) : Containers::Container
        end
        container_class.new(fragment)
      end
    end
  end
end
