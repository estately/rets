require_relative "helper"

class TestMetadataObject < MiniTest::Test
  def test_rets_object_build
    name = "Name"
    mime_type = "mimetype"
    description = "description"

    object_fragment = {
        "VisibleName" => name,
        "MIMEType"    => mime_type,
        "Description" => description,
    }

    assert_equal(
      Rets::Metadata::RetsObject.build(object_fragment),
      Rets::Metadata::RetsObject.new(name, mime_type, description)
    )
  end
end
