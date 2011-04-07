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
      ROW_CONTAINER_TYPES = %w(Resource Class Table Lookup LookupType Object)

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
    end
  end
end
