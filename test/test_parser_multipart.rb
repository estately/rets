require_relative "helper"

class TestParserMultipart < MiniTest::Test
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

  def test_parse_real_mls_data
    parts = Rets::Parser::Multipart.parse(MULTIPART_RESPONSE_URLS, "rets.object.content.boundary.1330546052739")
    assert_equal 5, parts.size
  end

  def test_parse_values_with_colon_data
    parts = Rets::Parser::Multipart.parse(MULTIPART_RESPONSE_URLS, "rets.object.content.boundary.1330546052739")
    assert_equal 'http://foobarmls.com/RETS//MediaDisplay/98/hr2890998-1.jpg', parts[0].headers['location']
  end

  def test_parse_with_error
    raw = "\r\n--89467f8e0c6b48158c8f1883910212ec\r\nContent-Type: text/xml\r\nContent-ID: foo\r\nObject-ID: *\r\n\r\n<RETS ReplyCode=\"999\" ReplyText=\"An Unexplaned Error\" />\r\n\r\n--89467f8e0c6b48158c8f1883910212ec--\r\n"
    boundary = "89467f8e0c6b48158c8f1883910212ec"
    assert_raises Rets::InvalidRequest do
      Rets::Parser::Multipart.parse(raw, boundary)
    end
  end
end
