module Rets
  module Metadata

    # Metadata caching.
    # @api internal
    class Caching

      # Given the options passed to Client#initialize, make an
      # instance.  Options:
      #
      # * :metadata_cache - Persistence mechanism.  Defaults to
      #   NullCache.
      #
      # * "metadata_serializer - Serialization mechanism.  Defaults to
      #   MarshalSerializer.
      def self.make(options)
        cache = options.fetch(:metadata_cache) { Metadata::NullCache.new }
        serializer = options.fetch(:metadata_serializer) do
          Metadata::MarshalSerializer.new
        end
        new(cache, serializer)
      end

      attr_reader :cache
      attr_reader :serializer

      # The cache is responsible for reading and writing the
      # serialized metadata.  The cache should quack like a
      # Rets::Metadata::FileCache.
      #
      # The serializer is responsible for serializing/deserializing
      # the metadata.  The serializer should quack like a
      # Rets::Metadata::MarshalSerializer.
      def initialize(cache, serializer)
        @cache = cache
        @serializer = serializer
      end

      # Load metadata.  Returns a Metadata::Root if successful, or nil
      # if it could be loaded for any reason.
      def load(logger)
        sources = @cache.load do |file|
          @serializer.load(file)
        end
        return nil unless sources.is_a?(Hash)
        Metadata::Root.new(logger, sources)
      end

      # Save metadata.
      def save(metadata)
        @cache.save do |file|
          @serializer.save(file, metadata.sources)
        end
      end
      
    end

  end
end
