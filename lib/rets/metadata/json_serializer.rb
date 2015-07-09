require 'json'

module Rets
  module Metadata

    # Serialize/Deserialize metadata using JSON.
    class JsonSerializer

      # Serialize to a file.  The library reserves the right to change
      # the type or contents of o, so don't depend on it being
      # anything in particular.
      def save(file, o)
        file.write o.to_json
      end

      # Deserialize from a file.  If the metadata cannot be
      # deserialized, return nil.
      def load(file)
        JSON.load(file)
      rescue JSON::ParserError
        nil
      end

    end
    
  end
end
