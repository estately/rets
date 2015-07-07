require_relative "helper"

class TestMetadataTableFactory < MiniTest::Test
  def test_table_fragments_produce_the_correct_types
    resource = mock
    resource.stubs(:id).returns('Resource')
    resource.stubs(:lookup_types).returns({})

    test_cases = {
      {"LookupName" => "Foo", "Interpretation"  => "Bar"}           => Rets::Metadata::Table,

      {"LookupName" => "Foo", "Interpretation"  => "Lookup"}        => Rets::Metadata::LookupTable,
      {"LookupName" => "",    "Interpretation"  => "Lookup"}        => Rets::Metadata::Table,

      {"LookupName" => "Foo", "Interpretation"  => "LookupMulti"}   => Rets::Metadata::MultiLookupTable,
      {"LookupName" => "",    "Interpretation"  => "LookupMulti"}   => Rets::Metadata::Table,
    }

    test_cases.each do |table_fragment, expected_klass|
      assert_instance_of expected_klass, Rets::Metadata::TableFactory.build(table_fragment, resource)
    end
  end
end
