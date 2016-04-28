require_relative "helper"

class TestMetadataObject < MiniTest::Test
  def test_rets_object_build
    name = "Name"
    mime_type = "mimetype"
    description = "description"
    object_type = "type"

    object_fragment = {
      "ObjectType" => object_type,
      "VisibleName" => name,
      "MIMEType"    => mime_type,
      "Description" => description,
    }

    assert_equal(
      Rets::Metadata::RetsObject.build(object_fragment),
      Rets::Metadata::RetsObject.new(object_type, name, mime_type, description)
    )
  end

  def test_rets_object_building_not_case_dependent
    object_fragment = {
      "MiMeTyPe" => "image/jpeg"
    }

    assert_equal(
      Rets::Metadata::RetsObject.build(object_fragment).mime_type,
      "image/jpeg"
    )
  end
end
