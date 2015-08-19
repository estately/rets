require_relative "helper"

class TestMetadataLookupTable < MiniTest::Test
  def setup
    $VERBOSE = true
  end

  def teardown
    $VERBOSE = false
  end

  def test_lookup_table_resolve_returns_single_value_if_not_multi
    fragment = {}
    lookup_types = [
      Rets::Metadata::LookupType.new("Value" => "A,B", "LongValue" => "AaaBbb")
    ]
    lookup_table = Rets::Metadata::LookupTable.new("Foo", lookup_types, fragment)

    assert_equal "AaaBbb", lookup_table.resolve("A,B")
  end
end
