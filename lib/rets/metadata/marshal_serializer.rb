require 'json'

module Rets
  module Metadata

    # Serialize/Deserialize metadata using Marshal.
    class MarshalSerializer

      # Serialize to a file.  The library reserves the right to change
      # the type or contents of o, so don't depend on it being
      # anything in particular.
      def save(file, o)
        Marshal.dump(o, file)
      end

      # Deserialize from a file.  If the metadata cannot be
      # deserialized, return nil.
      def load(file)
        Marshal.load(file)
      rescue TypeError
        nil
      end
      
    end
    
  end
end
