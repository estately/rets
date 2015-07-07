require_relative "helper"

class TestMetadataClass < MiniTest::Test
  def test_rets_class_find_table
    rets_class = Rets::Metadata::RetsClass.new({}, "resource")
    value = mock(:name => "test")

    rets_class.expects(:tables).returns([value])
    assert_equal(value, rets_class.find_table("test"))
  end

  def test_rets_class_find_table_container
    resource = mock(:id => "a")
    rets_class = mock(:name => "b")
    table = mock(:resource => "a", :class => "b")

    metadata = { :table => [table] }

    assert_equal(table, Rets::Metadata::RetsClass.find_table_container(metadata, resource, rets_class))
  end

  def test_rets_class_build
    resource = stub(:id => "id", :lookup_types => [])
    table_fragment = stub(:fragment)
    table_container = stub(:tables => [table_fragment])
    table = stub(:table)

    Rets::Metadata::TableFactory.expects(:build).with(table_fragment, anything, anything).returns(table)
    Rets::Metadata::RetsClass.expects(:find_table_container).returns(table_container)

    rets_class = Rets::Metadata::RetsClass.build({}, resource, "")

    assert_equal(rets_class.tables, [table])
  end

  def test_rets_class_build_when_find_table_container_returns_nil
    new_rets_class = stub(:new_rets_class)
    Rets::Metadata::RetsClass.stubs(:new => new_rets_class)
    Rets::Metadata::RetsClass.stubs(:find_table_container => nil)
    Rets::Metadata::RetsClass.build({}, "", "")
  end

  def test_rets_class_initialize
    fragment = { "ClassName" => "A" }
    rets_class = Rets::Metadata::RetsClass.new(fragment, "resource")

    assert_equal("A", rets_class.name)
    assert_equal("resource", rets_class.resource)
    assert_equal([], rets_class.tables)
  end
end
