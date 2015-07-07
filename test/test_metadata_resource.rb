require_relative "helper"

class TestMetadataResource < MiniTest::Test
  def test_resource_initialize
    fragment = { "ResourceID" => 'r' }
    resource = Rets::Metadata::Resource.new(fragment)
    assert_equal('r', resource.id)
    assert_equal([], resource.rets_classes)
  end

  def test_resource_build_lookup_tree
    metadata = stub(:metadata)
    resource = stub(:resource)

    Rets::Metadata::Resource.expects(:find_lookup_containers).
      with(metadata, resource).
      returns([stub(:lookups => [{"LookupName" => "Foo"}])])

    Rets::Metadata::Resource.expects(:find_lookup_type_containers).
      with(metadata, resource, "Foo").
      returns([stub(:lookup_types => [{"Value" => "111", "LongValue" => "Bar"}])])

    tree = Rets::Metadata::Resource.build_lookup_tree(resource, metadata)

    assert_equal ["Foo"], tree.keys
    assert_equal 1, tree["Foo"].size

    lookup_type = tree["Foo"].first

    assert_equal "111", lookup_type.value
    assert_equal "Bar", lookup_type.long_value
  end

  def test_resource_build_classes
    resource = stub(:resource)
    metadata = stub(:metadata)
    rets_class = stub(:rets_class)
    rets_class_fragment = stub(:rets_class_fragment)

    Rets::Metadata::RetsClass.expects(:build).with(rets_class_fragment, resource, metadata).returns(rets_class)
    Rets::Metadata::Resource.expects(:find_rets_classes).with(metadata, resource).returns([rets_class_fragment])

    classes = Rets::Metadata::Resource.build_classes(resource, metadata)
    assert_equal([rets_class], classes)
  end

  def test_resource_build
    fragment = { "ResourceID" => "test" }

    lookup_types = stub(:lookup_types)
    classes = stub(:classes)
    metadata = stub(:metadata)

    Rets::Metadata::Resource.stubs(:build_lookup_tree => lookup_types)
    Rets::Metadata::Resource.stubs(:build_classes => classes)

    resource = Rets::Metadata::Resource.build(fragment, metadata, Logger.new(STDOUT))

    assert_equal(lookup_types, resource.lookup_types)
    assert_equal(classes, resource.rets_classes)
  end

  def test_resource_build_with_incomplete_classes
    fragment = { "ResourceID" => "test" }

    lookup_types = stub(:lookup_types)
    metadata = stub(:metadata)

    Rets::Metadata::Resource.stubs(:build_lookup_tree => lookup_types)
    Rets::Metadata::Resource.stubs(:build_classes).raises(Rets::Metadata::Resource::MissingRetsClass)

    error_log = StringIO.new
    resource = Rets::Metadata::Resource.build(fragment, metadata, Logger.new(error_log))

    error_log.rewind
    error_msg = error_log.read
    assert error_msg.include?('MissingRetsClass')
    assert_equal(nil, resource)
  end

  def test_resource_find_lookup_containers
    resource = stub(:id => "id")
    metadata = { :lookup => [stub(:resource => "id"), stub(:resource => "id"), stub(:resource => "a")] }

    lookup_containers = Rets::Metadata::Resource.find_lookup_containers(metadata, resource)

    assert_equal(2, lookup_containers.size)
    assert_equal(["id", "id"], lookup_containers.map(&:resource))
  end

  def test_resource_find_lookup_type_containers
    resource = stub(:id => "id")
    metadata = { :lookup_type => [stub(:resource => "id", :lookup => "look"),
                                  stub(:resource => "id", :lookup => "look"),
                                  stub(:resource => "id", :lookup => "not_look"),
                                  stub(:resource => "a",  :lookup => "look"),
                                  stub(:resource => "a",  :lookup => "not_look")
                                 ]}

    lookup_type_containers = Rets::Metadata::Resource.find_lookup_type_containers(metadata, resource, "look")

    assert_equal(2, lookup_type_containers.size)
    assert_equal(["id", "id"], lookup_type_containers.map(&:resource))
  end

  def test_resource_find_rets_classes
    resource = stub(:id => "id")
    rets_classes = stub(:rets_classes)

    metadata = { :class => [stub(:resource => "id", :classes => rets_classes),
                            stub(:resource => "id", :classes => rets_classes),
                            stub(:resource => "a")]}

    assert_equal(rets_classes, Rets::Metadata::Resource.find_rets_classes(metadata, resource))
  end

  def test_resource_find_rets_class
    resource = Rets::Metadata::Resource.new({})
    value = mock(:name => "test")

    resource.expects(:rets_classes).returns([value])
    assert_equal(value, resource.find_rets_class("test"))
  end

end
