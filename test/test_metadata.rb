require "helper"

class TestMetadata < Test::Unit::TestCase
  def setup
    @root = Rets::Metadata::Root.new
  end

  def test_metadata_root_fetch_sources_returns_hash_of_metadata_types
    types = []
    fake_fetcher = lambda do |type|
      types << type
    end

    @root.fetch_sources(&fake_fetcher)

    assert_equal(Rets::Metadata::METADATA_TYPES, types)
  end

  def test_metadata_root_intialized_with_block
    external = false
    Rets::Metadata::Root.new { |source| external = true }
    assert external
  end

  def test_metadata_root_build_tree
    resource = stub(:id => "X")
    Rets::Metadata::Resource.stubs(:build => resource)
    resource_fragment = stub(:resource_fragment)
    resource_container = stub(:rows => [resource_fragment])
    @root.stubs(:metadata_types => { :resource => [resource_container] })
    assert_equal({"X" => resource}, @root.build_tree)
  end

  def test_metadata_root_version
    @root.instance_variable_set("@metadata_types", {:system => [stub(:version => "1")]})
    assert_equal "1", @root.version
  end

  def test_metadata_root_date
    @root.instance_variable_set("@metadata_types", {:system => [stub(:date => "1")]})
    assert_equal "1", @root.date
  end

  def test_metadata_root_current_version
    @root.stubs(:version).returns("1.2.2")
    @root.stubs(:date).returns("1")

    current_timestamp = "1"
    current_version = "1.2.3"

    assert !@root.current?(current_timestamp, current_version)
  end

  def test_metadata_root_current_timestamp
    @root.stubs(:version).returns("1.2.2")
    @root.stubs(:date).returns("1")

    current_timestamp = "2"
    current_version = "1.2.2"

    assert !@root.current?(current_timestamp, current_version)
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
    @root.stubs(:sources => test_sources, :build_containers => "Y--")
    @root.metadata_types = nil
    Nokogiri.stubs(:parse => "Y-")
    assert_equal({:x => "Y--", :z => "Y--"}, @root.metadata_types)
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
    assert([rets_class], classes)
  end

  def test_resource_build
    fragment = { "ResourceID" => "test" }

    lookup_types = stub(:lookup_types)
    classes = stub(:classes)
    metadata = stub(:metadata)

    Rets::Metadata::Resource.stubs(:build_lookup_tree => lookup_types)
    Rets::Metadata::Resource.stubs(:build_classes => classes)

    resource = Rets::Metadata::Resource.build(fragment, metadata)

    assert_equal(lookup_types, resource.lookup_types)
    assert_equal(classes, resource.rets_classes)
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

  def test_lookup_type_initialize
    fragment = { "Value" => 'a', "ShortValue" => 'b', "LongValue" => 'c' }

    lookup_type = Rets::Metadata::LookupType.new(fragment)

    assert_equal('a', lookup_type.value)
    assert_equal('b', lookup_type.short_value)
    assert_equal('c', lookup_type.long_value)
  end
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
    resource = stub(:resource)
    table_fragment = stub(:fragment)
    table_container = stub(:tables => [table_fragment])
    table = stub(:table)

    Rets::Metadata::TableFactory.expects(:build).with(table_fragment, resource).returns(table)
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

  def test_table_factory_creates_lookup_table
    assert_instance_of Rets::Metadata::LookupTable, Rets::Metadata::TableFactory.build({"LookupName" => "Foo", "Interpretation" => "Lookup"}, nil)
  end

  def test_table_factory_creates_table
    assert_instance_of Rets::Metadata::Table, Rets::Metadata::TableFactory.build({"LookupName" => "", "Interpretation" => ""}, nil)
  end

  def test_table_factory_enum
    assert Rets::Metadata::TableFactory.enum?("LookupName" => "Foo",  "Interpretation" => "Lookup")
    assert !Rets::Metadata::TableFactory.enum?("LookupName" => "",    "Interpretation" => "SomethingElse")
    assert !Rets::Metadata::TableFactory.enum?("LookupName" => "Foo", "Interpretation" => "")
    assert !Rets::Metadata::TableFactory.enum?("LookupName" => "",    "Interpretation" => "SomethingElse")
  end

  def test_lookup_table_initialize
    fragment = { "SystemName" => "A", "Interpretation" => "B", "LookupName" => "C" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, "Foo")

    assert_equal("Foo", lookup_table.resource)
    assert_equal("A", lookup_table.name)
    assert_equal("C", lookup_table.lookup_name)
    assert_equal("B", lookup_table.interpretation)
  end

  def test_lookup_table_resolve_returns_empty_array_when_value_is_empty
    fragment = { "Interpretation" => "SomethingElse" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    assert_equal [], lookup_table.resolve("")
  end

  def test_lookup_table_resolve_returns_single_value_array
    fragment = { "Interpretation" => "SomethingElse" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    lookup_table.expects(:lookup_type).with("A,B").returns(mock(:long_value => "AaaBbb"))

    assert_equal ["AaaBbb"], lookup_table.resolve("A,B")
  end

  def test_lookup_table_resolve_returns_multi_value_array_when_multi
    fragment = { "Interpretation" => "LookupMulti" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    lookup_table.expects(:lookup_type).with("A").returns(mock(:long_value => "Aaa"))
    lookup_table.expects(:lookup_type).with("B").returns(mock(:long_value => "Bbb"))

    assert_equal ["Aaa", "Bbb"], lookup_table.resolve("A,B")
  end

  #Sandicor does this :|
  def test_lookup_table_resolve_returns_multi_value_array_when_multi_with_quoted_values
    fragment = { "Interpretation" => "LookupMulti" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    lookup_table.expects(:lookup_type).with("A").returns(mock(:long_value => "Aaa"))
    lookup_table.expects(:lookup_type).with("B").returns(mock(:long_value => "Bbb"))

    assert_equal ["Aaa", "Bbb"], lookup_table.resolve(%q["A","B"])
  end

  # This scenario is unfortunately common.
  def test_lookup_table_resolve_returns_nil_when_lookup_type_is_not_present_for_multi_value
    fragment = { "Interpretation" => "LookupMulti" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    lookup_table.expects(:lookup_type).with("A").returns(mock(:long_value => "Aaa"))
    lookup_table.expects(:lookup_type).with("B").returns(nil)

    lookup_table.expects(:warn).with("Discarding unmappable value of #{"B".inspect}")

    assert_equal ["Aaa", nil], lookup_table.resolve("A,B")
  end

  # This scenario is unfortunately common.
  def test_lookup_table_resolve_returns_nil_when_lookup_type_is_not_present_for_single_value
    fragment = { "Interpretation" => "SomethingElse" }

    lookup_table = Rets::Metadata::LookupTable.new(fragment, nil)

    lookup_table.expects(:lookup_type).with("A").returns(nil)

    lookup_table.expects(:warn).with("Discarding unmappable value of #{"A".inspect}")

    assert_equal [nil], lookup_table.resolve("A")
  end

  def test_table_initialize
    fragment = { "DataType" => "A", "SystemName" => "B" }

    table = Rets::Metadata::Table.new(fragment)
    assert_equal("A", table.type)
    assert_equal("B", table.name)
  end

  def test_table_resolve_returns_empty_array_when_value_is_empty
    table = Rets::Metadata::Table.new({})

    assert_equal [], table.resolve("")
  end

  def test_table_resolve_returns_single_value_array
    table = Rets::Metadata::Table.new({})

    assert_equal ["Foo"], table.resolve("Foo")
  end

  def test_root_can_be_serialized
    sources = { :x => "a" }

    @root.sources = sources

    assert_equal sources, @root.marshal_dump
  end

  def test_root_can_be_unserialized
    sources = { :x => "a" }

    @root.marshal_load(sources)

    assert_equal sources, @root.sources
  end

end
