require_relative "helper"

class TestErrorChecker < MiniTest::Test
  def test_check_with_status_code_412
    response = mock
    response.stubs(:status_code).returns(412)
    response.stubs(:body).returns('junk')
    assert_raises Rets::HttpError do
      Rets::Parser::ErrorChecker.check(response)
    end
  end

  def test_401_with_empty_body_is_auth_failure
    # 401 with no body is an auth failure
    response = mock
    response.stubs(:status_code).returns(401)
    response.stubs(:ok?).returns(false)
    response.stubs(:body).returns('')
    assert_raises Rets::AuthorizationFailure do
      Rets::Parser::ErrorChecker.check(response)
    end
  end

  def test_401_with_html_body_is_auth_failure
    # 401 with html body returns auth failure
    response = mock
    response.stubs(:status_code).returns(401)
    response.stubs(:ok?).returns(false)
    response.stubs(:body).returns(HTML_AUTH_FAILURE)
    assert_raises Rets::AuthorizationFailure do
      Rets::Parser::ErrorChecker.check(response)
    end
  end

  def test_401_with_xhtml_body_is_auth_failure
    # 401 with xhtml body returns auth failure
    response = mock
    response.stubs(:status_code).returns(401)
    response.stubs(:ok?).returns(false)
    response.stubs(:body).returns(XHTML_AUTH_FAILURE)
    assert_raises Rets::AuthorizationFailure do
      Rets::Parser::ErrorChecker.check(response)
    end
  end

  def test_no_records_found_failure
    response = mock
    response.stubs(:body).returns(RETS_NO_RECORDS_ERROR)
    assert_raises Rets::NoRecordsFound do
      Rets::Parser::ErrorChecker.check(response)
    end
  end

  def test_no_object_found_failure
    response = mock
    response.stubs(:body).returns(RETS_NO_OBJECT_ERROR)
    assert_raises Rets::NoObjectFound do
      Rets::Parser::ErrorChecker.check(response)
    end
  end

  Rets::Parser::ErrorChecker::INVALID_REQUEST_ERROR_MAPPING.each do |error_code, error_class|
    define_method("test_#{error_class}_failure") do
      response = mock
      response.stubs(:body).returns(error_body_with_code(error_code))
      assert_raises error_class do
        Rets::Parser::ErrorChecker.check(response)
      end
    end
  end

  def test_invalid_request_failure
    response = mock
    response.stubs(:body).returns(RETS_INVALID_REQUEST_ERROR)
    assert_raises Rets::InvalidRequest do
      Rets::Parser::ErrorChecker.check(response)
    end
  end

  def error_body_with_code(code)
    <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="#{code}" ReplyText="Error message">
</RETS>
    XML
  end
end
