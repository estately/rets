require_relative "helper"

require "stringio"

class TestCaching < MiniTest::Test

  class MemoryCache

    def initialize
      reset
    end

    def save(&block)
      reset
      yield @io
    end

    def load(&block)
      @io.rewind
      yield @io
    end

    private

    def reset
      @io = StringIO.new
    end

  end

  def test_make_defaults
    caching = Rets::Metadata::Caching.make({})
    assert_instance_of Rets::Metadata::NullCache, caching.cache
    assert_instance_of Rets::Metadata::MarshalSerializer, caching.serializer
  end

  def test_round_trip
    logger = Logger.new("/dev/null")
    sources = {"foo" => "bar"}
    metadata = Rets::Metadata::Root.new(logger, sources)
    caching = Rets::Metadata::Caching.make(metadata_cache: MemoryCache.new)
    caching.save(metadata)
    loaded_metadata = caching.load(logger)
    assert_same logger, loaded_metadata.logger
    assert_equal sources, loaded_metadata.sources
  end

  def test_load_when_serializer_fails
    serializer = Class.new do
      def load(file)
        nil
      end
    end.new
    logger = Logger.new("/dev/null")
    caching = Rets::Metadata::Caching.make(
      metadata_cache: MemoryCache.new,
      metadata_serializer: serializer,
    )
    loaded_metadata = caching.load(logger)
    assert_nil loaded_metadata
  end

  def test_load_when_serializer_returns_wrong_type
    serializer = Class.new do
      def load(file)
        Object.new
      end
    end.new
    logger = Logger.new("/dev/null")
    caching = Rets::Metadata::Caching.make(
      metadata_cache: MemoryCache.new,
      metadata_serializer: serializer,
    )
    loaded_metadata = caching.load(logger)
    assert_nil loaded_metadata
  end

  def test_load_when_cache_fails
    logger = Logger.new("/dev/null")
    cache = stub
    cache.expects(:load).returns(nil)
    caching = Rets::Metadata::Caching.make(
      metadata_cache: cache,
    )
    loaded_metadata = caching.load(logger)
    assert_nil loaded_metadata
  end

end
