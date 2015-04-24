require_relative "helper"

class TestErrorChecker < MiniTest::Test

  def test_check_with_status_code_412
    response = mock
    response.stubs(:status_code).returns(412)
    response.stubs(:body).returns('junk')
    assert_raises Rets::HttpError do
      Rets::Client::ErrorChecker.check(response)
    end
  end

  def test_401_with_empty_body_is_auth_failure
    # 401 with no body is an auth failure
    response = mock
    response.stubs(:status_code).returns(401)
    response.stubs(:ok?).returns(false)
    response.stubs(:body).returns('')
    assert_raises Rets::AuthorizationFailure do
      Rets::Client::ErrorChecker.check(response)
    end
  end

  def test_401_with_html_body_is_auth_failure
    # 401 with html body returns auth failure
    response = mock
    response.stubs(:status_code).returns(401)
    response.stubs(:ok?).returns(false)
    response.stubs(:body).returns(HTML_AUTH_FAILURE)
    assert_raises Rets::AuthorizationFailure do
      Rets::Client::ErrorChecker.check(response)
    end
  end

end
