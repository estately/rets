require_relative "helper"

class TestMetadataRoot < MiniTest::Test
  def setup
    @root = Rets::Metadata::Root.new(Logger.new(STDOUT), {})
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
