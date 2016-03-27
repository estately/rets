require_relative "helper"

class TestMetadata < MiniTest::Test
  def test_metadata_uses
    #TODO
  end

  def test_print_tree
    hoa_lookup_types = [
      Rets::Metadata::LookupType.new("LongValue" => "Quarterly", "Value" => "Q"),
      Rets::Metadata::LookupType.new("LongValue" => "Annually", "Value" => "A"),
    ]

    table_fragment = {
      "Units" => "Meters",
      "Searchable" => "Y",
      'Required' => "N",

      "SystemName" => "L_1",
      "ShortName" => "Sq",
      "LongName" => "Square Footage",
      "StandardName" => "Sqft",
    }

    lookup_table_fragment = {
      "Required" => "N",
      "Searchable" => "Y",
      "Units" => "",
      "Interpretation" => "N",

      "SystemName" => "L_10",
      "ShortName" => "HF",
      "LongName" => "HOA Frequency",
      "StandardName" => "HOA F",
    }

    multi_lookup_table_fragment = {
      "Required" => "N",
      "Searchable" => "Y",
      "Units" => "",
      "Interpretation" => "N",

      "SystemName" => "L_11",
      "ShortName" => "HFs",
      "LongName" => "HOA Frequencies",
      "StandardName" => "HOA Fs",
    }

    resource_id = "Properties"
    tables = [
      Rets::Metadata::Table.new(table_fragment, resource_id),
      Rets::Metadata::LookupTable.new(resource_id, hoa_lookup_types, lookup_table_fragment),
      Rets::Metadata::MultiLookupTable.new(resource_id, hoa_lookup_types, multi_lookup_table_fragment),
    ]

    rets_classes = [
      Rets::Metadata::RetsClass.new("T100", "Prop", "standard name", "some description", tables)
    ]

    rets_objects = [
      Rets::Metadata::RetsObject.new("HiRes", "Photo", "photo/jpg", "photo description")
    ]

    resource = Rets::Metadata::Resource.new(resource_id, "matrix_unique_key", rets_classes, rets_objects)

    io = StringIO.new
    resource.print_tree(io)

    assert_equal io.string, EXAMPLE_METADATA_TREE
  end
end
