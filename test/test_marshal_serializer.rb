require_relative "helper"

require "stringio"

class TestMarshalSerializer < MiniTest::Test

  def setup
    @serializer = Rets::Metadata::MarshalSerializer.new
  end

  def test_round_trip
    metadata = {"foo" => "bar"}
    file = StringIO.new
    @serializer.save(file, metadata)
    file.rewind
    loaded = @serializer.load(file)
    assert_equal metadata, loaded
  end

  def test_bad_data
    file = StringIO.new("bad data")
    loaded = @serializer.load(file)
    assert_nil loaded
  end
  
end
