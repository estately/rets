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

  # RMLS does this. :|
  def test_remaining_columns_produce_empty_string_values
    column_names = "A B C D"
    data         = "1 2"

    assert_equal({"A" => "1", "B" => "2", "C" => "", "D" => ""}, Rets::Parser::Compact.parse(column_names, data, ' '))
  end

  def test_leading_empty_columns_are_preserved_with_delimiter
    column_names = "A\tB\tC\tD"
    data         = "\t\t3\t4" # first two columns are empty data.

    assert_equal({"A" => "", "B" => "", "C" => "3", "D" => "4"}, Rets::Parser::Compact.parse(column_names, data, "\t"))
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

  def test_get_count_with_unrecognized_document
    count = Rets::Parser::Compact.get_count("")
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

  def test_parse_html_encoded_chars
    rows = Rets::Parser::Compact.parse_document(SAMPLE_COMPACT_WITH_SPECIAL_CHARS)

    assert_equal "porte-coch\u{E8}re welcomes ", rows.last["PublicRemarksNew"]
  end

  def test_parse_html_encoded_chars_2
    rows = Rets::Parser::Compact.parse_document(SAMPLE_COMPACT_WITH_SPECIAL_CHARS_2)

    assert_equal "text with <tag>", rows.last["PublicRemarksNew"]
  end

  def test_parse_doubly_encoded_bad_character_references
    rows = Rets::Parser::Compact.parse_document(SAMPLE_COMPACT_WITH_DOUBLY_ENCODED_BAD_CHARACTER_REFERENCES)
    assert_equal "foo  bar", rows.last["PublicRemarksNew"]
  end

  def test_parse_property_with_lots_of_columns
    row = Rets::Parser::Compact.parse_document(SAMPLE_PROPERTY_WITH_LOTS_OF_COLUMNS).first
    assert_equal 800, row.keys.size
    assert_equal 800.times.map { |x| "K%03d" % x }, row.keys
  end

  def test_safely_decode_character_references!
    assert_decoded "a", "&#97;"
    assert_decoded "a", "&#097;"
    assert_decoded "a", "&#x61;"
    assert_decoded "a", "&#x061;"
    assert_decoded "", "&#xDC04;"
    assert_decoded "", "&#56324;"
    assert_decoded "", "&#x2000FF;"
  end


  def assert_decoded(a, b)
    recoded = Rets::Parser::Compact.safely_decode_character_references!(b)
    assert_equal a, recoded
  end
end
