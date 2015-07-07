require_relative "helper"

class TestMetadataClass < MiniTest::Test
  def test_rets_class_find_table
    rets_class = Rets::Metadata::RetsClass.new({})
    value = mock(:name => "test")

    rets_class.expects(:tables).returns([value])
    assert_equal(value, rets_class.find_table("test"))
  end

  def test_rets_class_find_table_container
    resource_id = "a"
    rets_class = mock(:name => "b")
    table = mock(:resource => resource_id, :class => "b")

    metadata = { :table => [table] }

    assert_equal(table, Rets::Metadata::RetsClass.find_table_container(metadata, resource_id, rets_class))
  end

  def test_rets_class_build
    resource_id = "id"
    lookup_types = []

    table_fragment = stub(:fragment)
    table_container = stub(:tables => [table_fragment])
    table = stub(:table)

    Rets::Metadata::TableFactory.expects(:build).with(table_fragment, resource_id, lookup_types).returns(table)
    Rets::Metadata::RetsClass.expects(:find_table_container).returns(table_container)

    rets_class = Rets::Metadata::RetsClass.build({}, resource_id, lookup_types, "")

    assert_equal(rets_class.tables, [table])
  end

  def test_rets_class_build_when_find_table_container_returns_nil
    new_rets_class = stub(:new_rets_class)
    Rets::Metadata::RetsClass.stubs(:new => new_rets_class)
    Rets::Metadata::RetsClass.stubs(:find_table_container => nil)
    Rets::Metadata::RetsClass.build({}, "resource_id", [], "")
  end

  def test_rets_class_initialize
    fragment = { "ClassName" => "A" }
    rets_class = Rets::Metadata::RetsClass.new(fragment)

    assert_equal("A", rets_class.name)
    assert_equal([], rets_class.tables)
  end
end
