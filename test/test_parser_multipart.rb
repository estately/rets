require "helper"

class TestParserMultipart < Test::Unit::TestCase
  def test_parse_returns_multiple_parts
    headers = {"content-type"=>"image/jpeg", "content-id"=>"90020062739", "content-length"=>"10"}

    parts = Rets::Parser::Multipart.parse(MULITPART_RESPONSE, "simple boundary")

    assert_equal 2, parts.size

    part = parts[0]

    assert_equal headers.merge("object-id" => "1"), part.headers
    assert_equal "xxxxxxxx", part.body.strip

    part = parts[1]

    assert_equal headers.merge("object-id" => "2"), part.headers
    assert_equal "yyyyyyyy", part.body.strip
  end
end
