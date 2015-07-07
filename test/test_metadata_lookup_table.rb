require_relative "helper"

class TestMetadataLookupTable < MiniTest::Test
  def test_lookup_table_initialize
    table_fragment = { "SystemName" => "A", "LookupName" => "C" }
    lookup_types = { }
    lookup_table = Rets::Metadata::LookupTable.new(table_fragment, lookup_types, "resource_id")

    assert_equal("resource_id", lookup_table.resource_id)
    assert_equal("A", lookup_table.name)
  end

  def test_lookup_table_resolve_returns_single_value_if_not_multi
    table_fragment = {}
    lookup_types = [
      Rets::Metadata::LookupType.new("LongValue" => "AaaBbb", "Value" => "A,B"),
    ]
    lookup_table = Rets::Metadata::LookupTable.new(table_fragment, lookup_types, "resource_id")

    assert_equal "AaaBbb", lookup_table.resolve("A,B")
  end

  def test_print_tree
    table_fragment = {
      "ShortName"    => "T",
      "StandardName" => "Table",
      "LongName"     => "Taaaaaaable",
      "SystemName"   => "T_100",
      "Required"     => "No",
      "Searchable"   => "Yes",
      "Units"        => "Lightyears",
    }
    lookup_table = Rets::Metadata::LookupTable.new(table_fragment, [], "resource_id")

    io = StringIO.new
    lookup_table.print_tree(io)
    assert_equal io.string, """    LookupTable: T_100
      Resource: resource_id
      Required: No
      Searchable: Yes
      Units: Lightyears
      ShortName: T
      LongName: Taaaaaaable
      StandardName: Table
      Types:
"""
  end
end
