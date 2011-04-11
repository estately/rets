require "helper"

class TestParserCompact < Test::Unit::TestCase
  def test_parse_document_raises_on_invalid_delimiter
    assert_raise Rets::Parser::Compact::InvalidDelimiter do
      Rets::Parser::Compact.parse_document(INVALID_DELIMETER)
    end
  end

  def test_parse_document_uses_default_delimiter_when_none_provided
    #  we assert that the delimeter character getting to parse is a tab
    #  even though COMPACT defines no delimiter tag
    Rets::Parser::Compact.expects(:parse).with("A\tB", "1\t2", "\t")
    Rets::Parser::Compact.expects(:parse).with("A\tB", "4\t5", "\t")
    Rets::Parser::Compact.parse_document(COMPACT)
  end

  def test_parse_document_delegates_to_parse
    result = Rets::Parser::Compact.parse_document(COMPACT)

    assert_equal [[%w(A 1), %w(B 2)], [%w(A 4), %w(B 5)]], result
  end

  def test_parser_ignores_leading_tabs
    result = Rets::Parser::Compact.parse_document(METADATA_OBJECT)

    result.each do |row|
      assert !row.any? { |k,v| k.to_s.size == 0 }, "Should not contain empty keys"
    end
  end

  def test_parse_returns_key_value_pairs
    result = Rets::Parser::Compact.parse("A\tB", "1\t2")

    assert_equal [%w(A 1), %w(B 2)], result
  end

  # RMLS does this. :|
  def test_remaining_columns_produce_empty_string_values
    columns = "A B C D"
    data    = "1 2"

    assert_equal [%w(A 1), %w(B 2), ["C", ""], ["D", ""]], Rets::Parser::Compact.parse(columns, data, " ")
  end
end
