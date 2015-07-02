require_relative "helper"

class TestMetadataLookupTable < MiniTest::Test
  def test_lookup_table_initialize
    fragment = { "SystemName" => "A", "LookupName" => "C" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, "Foo")

    assert_equal("Foo", lookup_table.resource)
    assert_equal("A", lookup_table.name)
    assert_equal("C", lookup_table.lookup_name)
  end

  def test_lookup_table_resolve_returns_single_value_if_not_multi
    lookup_table = Rets::Metadata::LookupTable.new({}, nil)
    lookup_table.stubs(:multi? => false)

    lookup_table.expects(:lookup_type).with("A,B").returns(mock(:long_value => "AaaBbb"))

    assert_equal "AaaBbb", lookup_table.resolve("A,B")
  end
end
