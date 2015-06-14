require_relative "helper"

require "tempfile"

class TestFileCache < MiniTest::Test

  def with_tempfile(&block)
    Tempfile.open(File.basename(__FILE__), &block)
  end

  def with_temp_path
    with_tempfile do |file|
      path = file.path
      begin
        file.close!
        yield path
      ensure
        File.delete(path)
      end
    end
  end

  def test_save
    with_temp_path do |path|
      cache = Rets::Metadata::FileCache.new(path)
      cache.save { |file| file.print "foo" }
      file_contents = File.read(path)
      assert_equal "foo", file_contents
    end
  end

  def test_load
    with_tempfile do |file|
      file.print "foo"
      file.close
      cache = Rets::Metadata::FileCache.new(file.path)
      file_contents = cache.load(&:read)
      assert_equal "foo", file_contents
    end
  end

end
