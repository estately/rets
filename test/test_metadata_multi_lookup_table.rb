require_relative "helper"

class TestMetadataMultiLookupTable < MiniTest::Test
  def setup
    $VERBOSE = true
  end

  def teardown
    $VERBOSE = false
  end

  def test_lookup_table_resolve_returns_empty_array_when_value_is_empty_and_is_multi?
    lookup_table = Rets::Metadata::MultiLookupTable.new({}, {}, "resource_id")
    assert_equal [], lookup_table.resolve("")
  end

  def test_lookup_table_resolve_returns_multi_value_array_when_multi
    fragment = { "Interpretation" => "LookupMulti" }
    lookup_types = [
      Rets::Metadata::LookupType.new("LongValue" => "Aaa", "Value" => "A"),
      Rets::Metadata::LookupType.new("LongValue" => "Bbb", "Value" => "B"),
    ]
    lookup_table = Rets::Metadata::MultiLookupTable.new(fragment, lookup_types, "resource_id")

    assert_equal ["Aaa", "Bbb"], lookup_table.resolve("A,B")
  end

  #Sandicor does this :|
  def test_lookup_table_resolve_returns_multi_value_array_when_multi_with_quoted_values
    fragment = { "Interpretation" => "LookupMulti" }
    lookup_types = [
      Rets::Metadata::LookupType.new("LongValue" => "Aaa", "Value" => "A"),
      Rets::Metadata::LookupType.new("LongValue" => "Bbb", "Value" => "B"),
    ]
    lookup_table = Rets::Metadata::MultiLookupTable.new(fragment, lookup_types, "resource_id")

    assert_equal ["Aaa", "Bbb"], lookup_table.resolve(%q["A","B"])
  end

  # This scenario is unfortunately common.
  def test_lookup_table_resolve_returns_nil_when_lookup_type_is_not_present_for_multi_value
    fragment = { "Interpretation" => "LookupMulti" }
    lookup_types = [
      Rets::Metadata::LookupType.new("LongValue" => "Aaa", "Value" => "A"),
    ]
    lookup_table = Rets::Metadata::MultiLookupTable.new(fragment, lookup_types, "resource_id")
    lookup_table.lookup_table.expects(:warn).with("Discarding unmappable value of #{"B".inspect}")

    assert_equal ["Aaa", ""], lookup_table.resolve("A,B")
  end

  # This scenario is unfortunately common.
  def test_lookup_table_resolve_returns_nil_when_lookup_type_is_not_present_for_single_value
    fragment = { "Interpretation" => "LookupMulti" }
    lookup_types = []

    lookup_table = Rets::Metadata::MultiLookupTable.new(fragment, lookup_types, "resource_id")
    lookup_table.lookup_table.expects(:warn).with("Discarding unmappable value of #{"A".inspect}")

    assert_equal [""], lookup_table.resolve("A")
  end
end
