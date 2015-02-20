module Rets
  module Metadata
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
              fields_hash[field] || fields_hash[field] = extract(fragment, field.to_s.capitalize)
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

        private

        def fields_hash
          @fields ||= {}
        end

      end

      class RowContainer < Container

        attr_accessor :rows

        def initialize(doc)
          super
          self.rows = Parser::Compact.parse_document(doc)
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
