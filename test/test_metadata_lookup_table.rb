require_relative "helper"

class TestMetadataLookupTable < MiniTest::Test
  def setup
    $VERBOSE = true
  end

  def teardown
    $VERBOSE = false
  end

  def test_lookup_table_initialize
    fragment = { "SystemName" => "A", "Interpretation" => "B", "LookupName" => "C" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, "Foo")

    assert_equal("Foo", lookup_table.resource)
    assert_equal("A", lookup_table.name)
    assert_equal("C", lookup_table.lookup_name)
    assert_equal("B", lookup_table.interpretation)
  end

  def test_lookup_table_resolve_returns_empty_array_when_value_is_empty_and_is_multi?

    lookup_table = Rets::Metadata::LookupTable.new({}, nil)
    lookup_table.stubs(:multi? => true)

    assert_equal [], lookup_table.resolve("")
  end

  def test_lookup_table_resolve_returns_single_value_if_not_multi
    lookup_table = Rets::Metadata::LookupTable.new({}, nil)
    lookup_table.stubs(:multi? => false)

    lookup_table.expects(:lookup_type).with("A,B").returns(mock(:long_value => "AaaBbb"))

    assert_equal "AaaBbb", lookup_table.resolve("A,B")
  end

  def test_lookup_table_resolve_returns_multi_value_array_when_multi
    fragment = { "Interpretation" => "LookupMulti" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    lookup_table.expects(:lookup_type).with("A").returns(mock(:long_value => "Aaa"))
    lookup_table.expects(:lookup_type).with("B").returns(mock(:long_value => "Bbb"))

    assert_equal ["Aaa", "Bbb"], lookup_table.resolve("A,B")
  end

  #Sandicor does this :|
  def test_lookup_table_resolve_returns_multi_value_array_when_multi_with_quoted_values
    fragment = { "Interpretation" => "LookupMulti" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    lookup_table.expects(:lookup_type).with("A").returns(mock(:long_value => "Aaa"))
    lookup_table.expects(:lookup_type).with("B").returns(mock(:long_value => "Bbb"))

    assert_equal ["Aaa", "Bbb"], lookup_table.resolve(%q["A","B"])
  end

  # This scenario is unfortunately common.
  def test_lookup_table_resolve_returns_nil_when_lookup_type_is_not_present_for_multi_value
    fragment = { "Interpretation" => "LookupMulti" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    lookup_table.expects(:lookup_type).with("A").returns(mock(:long_value => "Aaa"))
    lookup_table.expects(:lookup_type).with("B").returns(nil)

    lookup_table.expects(:warn).with("Discarding unmappable value of #{"B".inspect}")

    assert_equal ["Aaa", ""], lookup_table.resolve("A,B")
  end

  # This scenario is unfortunately common.
  def test_lookup_table_resolve_returns_nil_when_lookup_type_is_not_present_for_single_value

    lookup_table = Rets::Metadata::LookupTable.new({}, nil)
    lookup_table.stubs(:multi? => true)

    lookup_table.expects(:lookup_type).with("A").returns(nil)

    lookup_table.expects(:warn).with("Discarding unmappable value of #{"A".inspect}")

    assert_equal [""], lookup_table.resolve("A")
  end
end
