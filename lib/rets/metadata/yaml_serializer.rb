require 'yaml'

module Rets
  module Metadata

    # Serialize/Deserialize metadata using Marshal.
    class YamlSerializer

      # Serialize to a file.  The library reserves the right to change
      # the type or contents of o, so don't depend on it being
      # anything in particular.
      def save(file, o)
        YAML.dump(o, file)
      end

      # Deserialize from a file.  If the metadata cannot be
      # deserialized, return nil.
      def load(file)
        YAML.load(file)
      rescue Psych::SyntaxError
        nil
      end

    end
    
  end
end
