module Rets
  module Metadata

    # This type of metadata cache, which is the default, neither saves
    # nor restores.
    class NullCache

      # Save the metadata.  Should yield an IO-like object to a block;
      # that block will serialize the metadata to that object.
      def save(&_block)
      end

      # Load the metadata.  Should yield an IO-like object to a block;
      # that block will deserialize the metadata from that object and
      # return the metadata.  Returns the metadata, or nil if it could
      # not be loaded.
      def load(&_block)
        nil
      end
      
    end
    
  end
end
