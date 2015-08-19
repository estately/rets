require_relative "helper"

class TestMetadataTableFactory < MiniTest::Test
  def test_table_factory_enum
    assert Rets::Metadata::TableFactory.enum?("LookupName" => "Foo",  "Interpretation" => "Lookup")
    assert !Rets::Metadata::TableFactory.enum?("LookupName" => "",    "Interpretation" => "SomethingElse")
    assert !Rets::Metadata::TableFactory.enum?("LookupName" => "Foo", "Interpretation" => "")
    assert !Rets::Metadata::TableFactory.enum?("LookupName" => "",    "Interpretation" => "SomethingElse")
  end

  def test_table_factory_creates_lookup_table
    table_fragment = {"LookupName" => "Foo", "Interpretation" => "Lookup"}
    resource_id = "id"
    lookup_types = {}
    assert_instance_of Rets::Metadata::LookupTable, Rets::Metadata::TableFactory.build(table_fragment, resource_id, lookup_types)
  end

  def test_table_factory_creates_table
    table_fragment = {"LookupName" => "", "Interpretation" => ""}
    resource_id = "id"
    lookup_types = {}
    assert_instance_of Rets::Metadata::Table, Rets::Metadata::TableFactory.build(table_fragment, resource_id, lookup_types)
  end
end
