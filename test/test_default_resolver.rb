require_relative "helper"

class TestDefaultResolver < MiniTest::Test
  def setup
    @client_progress = Rets::ClientProgressReporter.new(Rets::Client::FakeLogger.new, nil, nil)
    @resolver = Rets::DefaultResolver.new
  end

  def test_decorate_result_handles_bad_metadata
    result = {'table_name' => 'short_value'}

    rets_class = stub
    rets_class.expects(:find_table).with('table_name').returns(nil)

    response = @resolver.decorate_result(result, rets_class, @client_progress)

    assert_equal response, result
  end

  def test_decorate_result
    result = {'table_name' => 'short_value'}

    rets_table = stub
    rets_table.expects(:resolve).with('short_value').returns('long_value')

    rets_class = stub
    rets_class.expects(:find_table).with('table_name').returns(rets_table)

    assert_equal @resolver.decorate_result(result, rets_class, @client_progress), { 'table_name' => 'long_value' }
  end
end
