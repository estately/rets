module Rets
  module Metadata

    # This metadata cache persists the metadata to a file.
    class FileCache

      def initialize(path)
        @path = path
      end

      # Save the metadata.  Should yield an IO-like object to a block;
      # that block will serialize the metadata to that object.
      def save(&block)
        File.open(@path, "wb", &block)
      end

      # Load the metadata.  Should yield an IO-like object to a block;
      # that block will deserialize the metadata from that object and
      # return the metadata.  Returns the metadata, or nil if it could
      # not be loaded.
      def load(&block)
        File.open(@path, "rb", &block)
      rescue IOError, SystemCallError
        nil
      end
    end
    
  end
end
