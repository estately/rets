require "helper"

class TestMetadata < Test::Unit::TestCase
  def test_metadata_build_uses_row_containers_for_resource
    doc = Nokogiri.parse(METADATA_RESOURCE)

    containers = Rets::Metadata.build(doc)

    assert_equal 1, containers.size

    resource_container = containers.first

    assert_instance_of Rets::Metadata::ResourceContainer, resource_container

    assert_equal 13, resource_container.resources.size

    resource = resource_container.resources.first

    assert_equal "ActiveAgent", resource["StandardName"]
  end

  def test_metadata_build_uses_system_container_for_system
    doc = Nokogiri.parse(METADATA_SYSTEM)

    containers = Rets::Metadata.build(doc)

    assert_equal 1, containers.size

    assert_instance_of Rets::Metadata::SystemContainer, containers.first
  end

  def test_metadata_build_uses_base_container_for_unknown_metadata_types
    doc = Nokogiri.parse(METADATA_UNKNOWN)

    containers = Rets::Metadata.build(doc)

    assert_equal 1, containers.size

    assert_instance_of Rets::Metadata::Container, containers.first
  end

  def test_metadata_uses
    #TODO
  end
end
