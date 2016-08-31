require_relative "helper"

class TestMetadataResource < MiniTest::Test
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
    resource_id = "id"
    lookup_types = []

    metadata = stub(:metadata)
    rets_class = stub(:rets_class)
    rets_class_fragment = stub(:rets_class_fragment)

    Rets::Metadata::RetsClass.expects(:build).with(rets_class_fragment, resource_id, lookup_types, metadata).returns(rets_class)
    Rets::Metadata::Resource.expects(:find_rets_classes).with(metadata, resource_id).returns([rets_class_fragment])

    classes = Rets::Metadata::Resource.build_classes(resource_id, lookup_types, metadata)
    assert_equal([rets_class], classes)
  end

  def test_resource_build_objects
    resource_id = "id"

    metadata = stub(:metadata)
    rets_object = stub(:rets_object)
    rets_object_fragment = stub(:rets_object_fragment)

    Rets::Metadata::RetsObject.expects(:build).with(rets_object_fragment).returns(rets_object)
    Rets::Metadata::Resource.expects(:find_rets_objects).with(metadata, resource_id).returns([rets_object_fragment])

    objects = Rets::Metadata::Resource.build_objects(resource_id, metadata)
    assert_equal([rets_object], objects)
  end

  def test_resource_build_objects_when_objects_were_not_loaded
    resource_id = "id"
    metadata    = {} # doesn't contain metadata for :object key

    objects = Rets::Metadata::Resource.build_objects(resource_id, metadata)
    assert_equal [], objects
  end

  def test_resource_build
    fragment = { "ResourceID" => "test" }

    lookup_types = stub(:lookup_types)
    classes = stub(:classes)
    objects = stub(:objects)
    metadata = stub(:metadata)

    Rets::Metadata::Resource.stubs(:build_lookup_tree => lookup_types)
    Rets::Metadata::Resource.stubs(:build_classes => classes)
    Rets::Metadata::Resource.stubs(:build_objects => objects)

    resource = Rets::Metadata::Resource.build(fragment, metadata, Logger.new(STDOUT))

    assert_equal(classes, resource.rets_classes)
    assert_equal(objects, resource.rets_objects)
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
    resource_id = "id"
    metadata = {
      :lookup => [
        stub(:resource => resource_id),
        stub(:resource => resource_id),
        stub(:resource => "a")
      ]
    }

    lookup_containers = Rets::Metadata::Resource.find_lookup_containers(metadata, resource_id)

    assert_equal(2, lookup_containers.size)
    assert_equal(["id", "id"], lookup_containers.map(&:resource))
  end

  def test_resource_find_lookup_type_containers
    resource_id = "id"
    metadata = {
      :lookup_type => [
        stub(:resource => resource_id, :lookup => "look"),
        stub(:resource => resource_id, :lookup => "look"),
        stub(:resource => resource_id, :lookup => "not_look"),
        stub(:resource => "a",         :lookup => "look"),
        stub(:resource => "a",         :lookup => "not_look")
      ]
    }
    lookup_type_containers = Rets::Metadata::Resource.find_lookup_type_containers(metadata, resource_id, "look")

    assert_equal(2, lookup_type_containers.size)
    assert_equal(["id", "id"], lookup_type_containers.map(&:resource))
  end

  def test_resource_find_rets_classes
    rets_classes = stub(:rets_classes)

    metadata = { :class => [stub(:resource => "id", :classes => rets_classes),
                            stub(:resource => "id", :classes => rets_classes),
                            stub(:resource => "a")]}

    assert_equal(rets_classes, Rets::Metadata::Resource.find_rets_classes(metadata, "id"))
  end

  def test_resource_find_rets_class
    rets_class = Rets::Metadata::RetsClass.new('test', '', '', '', [])
    resource = Rets::Metadata::Resource.new('', '', [rets_class], [])
    assert_equal(rets_class, resource.find_rets_class("test"))
  end
end
