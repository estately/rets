require_relative "helper"

class TestMetadataLookupType < MiniTest::Test
  def test_lookup_type_initialize
    fragment = { "Value" => 'a', "ShortValue" => 'b', "LongValue" => 'c' }

    lookup_type = Rets::Metadata::LookupType.new(fragment)

    assert_equal('a', lookup_type.value)
    assert_equal('b', lookup_type.short_value)
    assert_equal('c', lookup_type.long_value)
  end
end
