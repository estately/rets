require_relative "helper"

class TestMetadataTableFactory < MiniTest::Test
  def test_table_factory_creates_multi_lookup_table
    assert_instance_of Rets::Metadata::MultiLookupTable, Rets::Metadata::TableFactory.build({"LookupName" => "Foo", "Interpretation" => "LookupMulti"}, nil)
  end

  def test_table_factory_creates_lookup_table
    assert_instance_of Rets::Metadata::LookupTable, Rets::Metadata::TableFactory.build({"LookupName" => "Foo", "Interpretation" => "Lookup"}, nil)
  end

  def test_table_factory_creates_table
    assert_instance_of Rets::Metadata::Table, Rets::Metadata::TableFactory.build({"LookupName" => "", "Interpretation" => ""}, nil)
  end

  def test_table_factory_enum
    assert Rets::Metadata::TableFactory.lookup_table?("LookupName" => "Foo",  "Interpretation" => "Lookup")
    assert !Rets::Metadata::TableFactory.lookup_table?("LookupName" => "",    "Interpretation" => "SomethingElse")
    assert !Rets::Metadata::TableFactory.lookup_table?("LookupName" => "Foo", "Interpretation" => "")
    assert !Rets::Metadata::TableFactory.lookup_table?("LookupName" => "",    "Interpretation" => "SomethingElse")
  end
end
