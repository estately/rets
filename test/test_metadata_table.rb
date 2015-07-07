require_relative "helper"

class TestMetadataTable < MiniTest::Test
  def test_table_initialize
    fragment = { "DataType" => "A", "SystemName" => "B" }

    table = Rets::Metadata::Table.new(fragment, "resource_id")
    assert_equal("A", table.type)
    assert_equal("B", table.name)
  end

  def test_table_resolve_returns_empty_string_when_value_nil
    table = Rets::Metadata::Table.new({}, "resource_id")

    assert_equal "", table.resolve(nil)
  end

  def test_table_resolve_passes_values_straight_through
    table = Rets::Metadata::Table.new({}, "resource_id")

    assert_equal "Foo", table.resolve("Foo")
  end

  def test_table_resolve_passes_values_strips_extra_whitspace
    table = Rets::Metadata::Table.new({}, "resource_id")

    assert_equal "Foo", table.resolve(" Foo ")
  end
end
