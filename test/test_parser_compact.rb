require_relative "helper"

class TestParserCompact < MiniTest::Test
  def test_parse_document_raises_on_invalid_delimiter
    assert_raises Rets::Parser::Compact::InvalidDelimiter do
      Rets::Parser::Compact.parse_document(INVALID_DELIMETER)
    end
  end

  def test_parse_document_delegates_to_parse
    result = Rets::Parser::Compact.parse_document(COMPACT)

    assert_equal([{"A" => "1", "B" => "2"}, {"A" => "4", "B" => "5"}], result)
  end

  def test_parser_rejects_empty_key_value_pairs
    result = Rets::Parser::Compact.parse_document(METADATA_OBJECT)

    result.each do |row|
      assert !row.any? { |k,v| k.to_s.size == 0 }, "Should not contain empty keys"
    end
  end

  def test_parse_returns_key_value_pairs
    result = Rets::Parser::Compact.parse("A\tB", "1\t2")

    assert_equal({"A" => "1", "B" => "2"}, result)
  end

  # RMLS does this. :|
  def test_remaining_columns_produce_empty_string_values
    columns = "A B C D"
    data    = "1 2"

    assert_equal({"A" => "1", "B" => "2", "C" => "", "D" => ""}, Rets::Parser::Compact.parse(columns, data, ' '))
  end

  def test_leading_empty_columns_are_preserved_with_delimiter
    columns = "A\tB\tC\tD"
    data    = "\t\t3\t4" # first two columns are empty data.

    assert_equal({"A" => "", "B" => "", "C" => "3", "D" => "4"}, Rets::Parser::Compact.parse(columns, data, "\t"))
  end

  def test_parse_empty_document
    rows = Rets::Parser::Compact.parse_document(EMPTY_COMPACT)
    assert_equal [], rows
  end

  def test_get_count
    count = Rets::Parser::Compact.get_count(COUNT_ONLY)
    assert_equal 1234, count
  end

  def test_get_count_with_no_matching_records
    count = Rets::Parser::Compact.get_count(RETS_STATUS_NO_MATCHING_RECORDS)
    assert_equal 0, count
  end

  def test_parse_example
    rows = Rets::Parser::Compact.parse_document(SAMPLE_COMPACT)

    assert_equal "7", rows.first["MetadataEntryID"]
  end

  def test_parse_example_2
    rows = Rets::Parser::Compact.parse_document(SAMPLE_COMPACT_2)

    assert_equal "", rows.first["ModTimeStamp"]
  end

  def test_parse_with_changed_delimiter
    rows = Rets::Parser::Compact.parse_document(CHANGED_DELIMITER)

    assert_equal [{"A" => "1", "B" => "2"}, {"A" => "4", "B" => "5"}], rows
  end

end
