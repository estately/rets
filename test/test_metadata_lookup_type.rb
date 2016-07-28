require_relative "helper"

class TestMetadataLookupType < MiniTest::Test
  def test_lookup_type_initialize
    fragment = { "Value" => 'a', "LongValue" => 'c' }

    lookup_type = Rets::Metadata::LookupType.new(fragment)

    assert_equal('a', lookup_type.value)
    assert_equal('c', lookup_type.long_value)
  end

  def test_lookup_type_ignores_trailing_whitespace
    fragment = { "Value" => 'a     ', "LongValue" => 'c     ' }

    lookup_type = Rets::Metadata::LookupType.new(fragment)

    assert_equal('a', lookup_type.value)
    assert_equal('c', lookup_type.long_value)
  end
end
