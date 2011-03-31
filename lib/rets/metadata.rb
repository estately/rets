module Rets
  module Metadata
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


    # Returns an array of container classes that represents
    # the metadata stored in the document provided.
    def self.build(doc)

      # find all tags that match /RETS/METADATA-*
      fragments = doc.xpath("/RETS/*[starts-with(name(), 'METADATA-')]")

      fragments.map do |fragment|
        build_container(fragment)
      end
    end

    def self.build_container(fragment)
      tag  = fragment.name             # METADATA-RESOURCE
      type = tag.sub(/^METADATA-/, "") # RESOURCE

      class_name = type.capitalize.gsub(/_(\w)/) { $1.upcase }
      container_name = "#{class_name}Container"

      container_class = constants.include?(container_name) ? const_get(container_name) : Container
      container_class.new(fragment)
    end

  end
end

