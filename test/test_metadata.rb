require_relative "helper"
require 'logger'

class TestMetadata < MiniTest::Test
  def setup
    @root = Rets::Metadata::Root.new(Logger.new(STDOUT), {})
    $VERBOSE = true
  end

  def teardown
    $VERBOSE = false
  end

  def test_print_tree
    resource = Rets::Metadata::Resource.new("Foo", [], {}, "Bar")

    io = StringIO.new
    resource.print_tree(io)
    assert_equal io.string, "Resource: Foo (Key Field: Bar)\n"
  end

  def test_metadata_root_build_tree
    resource = stub(:id => "X")
    Rets::Metadata::Resource.stubs(:build => resource)
    resource_fragment = stub(:resource_fragment)
    resource_container = stub(:rows => [resource_fragment])
    @root.stubs(:metadata_types => { :resource => [resource_container] })
    assert_equal({"x" => resource}, @root.build_tree)
    assert_equal(resource, @root.build_tree["X"])
  end

  def test_metadata_root_version
    @root.instance_variable_set("@metadata_types", {:system => [stub(:version => "1")]})
    assert_equal "1", @root.version
  end

  def test_metadata_root_date
    @root.instance_variable_set("@metadata_types", {:system => [stub(:date => "1")]})
    assert_equal "1", @root.date
  end

  def test_metadata_root_different_version
    @root.stubs(:version).returns("1.2.2")
    @root.stubs(:date).returns("1")

    current_version = "1.2.3"
    current_timestamp = "1"

    assert !@root.current?(current_timestamp, current_version)
  end

  def test_metadata_root_same_version
    @root.stubs(:version).returns("1.2.2")
    @root.stubs(:date).returns("1")

    current_version = "1.2.2"
    current_timestamp = "2"

    assert @root.current?(current_timestamp, current_version)
  end

  def test_metadata_root_no_version_same_timestamp
    @root.stubs(:version).returns("")
    @root.stubs(:date).returns("1")

    current_version = "1.2.3"
    current_timestamp = "1"

    assert @root.current?(current_timestamp, current_version)
  end

  def test_metadata_root_current
    @root.stubs(:version).returns("1.2.2")
    @root.stubs(:date).returns("1")

    current_timestamp = "1"
    current_version = "1.2.2"

    assert @root.current?(current_timestamp, current_version)
  end

  # missing timestamp - this happens in violation of the spec.
  def test_metadata_root_current_ignores_missing_timestamp
    @root.stubs(:version).returns("1.2.2")
    @root.stubs(:date).returns("1")

    current_timestamp = nil
    current_version = "1.2.2"

    assert @root.current?(current_timestamp, current_version)
  end

  # missing version - this happens in violation of the spec.
  def test_metadata_root_current_ignores_missing_version
    @root.stubs(:version).returns("1.2.2")
    @root.stubs(:date).returns("1")

    current_timestamp = "1"
    current_version = nil

    assert @root.current?(current_timestamp, current_version)
  end

  def test_metadata_root_metadata_types_constructs_a_hash_of_metadata_types_from_sources
    test_sources = { "X" => "Y", "Z" => "W" }
    root = Rets::Metadata::Root.new(stub(:logger), test_sources)
    root.stubs(:build_containers => "Y--")
    Nokogiri.stubs(:parse => "Y-")

    assert_equal({:x => "Y--", :z => "Y--"}, root.metadata_types)
  end

  def test_metadata_root_build_containers_selects_correct_tags
    doc = "<RETS><METADATA-FOO></METADATA-FOO><MET-FOO></MET-FOO><METADATA-BAR /></RETS>"

    @root.expects(:build_container).with { |fragment| fragment.name == "METADATA-FOO" }
    @root.expects(:build_container).with { |fragment| fragment.name == "METADATA-BAR" }

    @root.build_containers(Nokogiri.parse(doc))
  end

  def test_metadata_root_build_container_uses_row_containers_for_resource
    doc = Nokogiri.parse(METADATA_RESOURCE).xpath("//METADATA-RESOURCE").first

    container = @root.build_container(doc)

    assert_instance_of Rets::Metadata::Containers::ResourceContainer, container

    assert_equal 13, container.resources.size

    resource = container.resources.first

    assert_equal "ActiveAgent", resource["StandardName"]
  end

  def test_metadata_root_build_container_uses_system_container_for_system
    doc = Nokogiri.parse(METADATA_SYSTEM).xpath("//METADATA-SYSTEM").first

    container = @root.build_container(doc)
    assert_instance_of Rets::Metadata::Containers::SystemContainer, container
  end

  def test_metadata_root_build_container_uses_base_container_for_unknown_metadata_types
    doc = Nokogiri.parse(METADATA_UNKNOWN).xpath("//METADATA-FOO").first

    container = @root.build_container(doc)
    assert_instance_of Rets::Metadata::Containers::Container, container
  end

  def test_metadata_uses
    #TODO
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
    rets_class = mock(:name => "test")
    resource = Rets::Metadata::Resource.new('id', [rets_class], {}, 'key_field')
    assert_equal(rets_class, resource.find_rets_class("test"))
  end

  def test_lookup_type_initialize
    fragment = { "Value" => 'a', "ShortValue" => 'b', "LongValue" => 'c' }

    lookup_type = Rets::Metadata::LookupType.new(fragment)

    assert_equal('a', lookup_type.value)
    assert_equal('b', lookup_type.short_value)
    assert_equal('c', lookup_type.long_value)
  end

  def test_root_can_be_serialized
    sources = { :x => "a" }
    root = Rets::Metadata::Root.new(stub(:logger), sources)
    assert_equal sources, root.marshal_dump
  end

  def test_root_can_be_unserialized
    logger = stub(:logger)
    sources = { :x => "a" }

    root_to_serialize = Rets::Metadata::Root.new(logger, sources)
    new_root = Rets::Metadata::Root.new(logger, root_to_serialize.marshal_dump)

    assert_equal root_to_serialize.marshal_dump, new_root.marshal_dump
  end
end
