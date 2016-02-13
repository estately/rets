require_relative "helper"

class TestPropertyClient < MiniTest::Test
  def setup
    @mls_config = Rets::MlsConfiguration.new
    @mls_config.mls = 'TestMls'
    @mls_config.property_key_field = 'ListingID'
    @mls_config.property_class = 'RESI'
    @mls_config.property_modified_key_field = "ModifiedDate"
    @property_client = Rets::PropertyClient.new(@mls_config)
  end

  def test_build_property_params
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+)" }
    assert_equal exp_prop_params, @property_client.build_property_params
  end

  def test_build_property_params_with_property_resource_type
    @mls_config.property_resource_type = 'Listings'
    exp_prop_params = { :search_type => "Listings", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+)" }
    assert_equal exp_prop_params, @property_client.build_property_params
  end

  def test_build_property_params_with_nonnumeric_property_key_field
    @mls_config.property_key_field_numeric = false
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=*)" }
    assert_equal exp_prop_params, @property_client.build_property_params
  end

  def test_build_property_params_with_start_at_string
    start_at = "2016-02-13T22:24:35+00:00"
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+),(ModifiedDate=#{start_at}+)" }
    assert_equal exp_prop_params, @property_client.build_property_params(:start_at => start_at)
  end

  def test_build_property_params_with_start_at_time
    start_at = Time.now
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+),(ModifiedDate=#{start_at.utc.strftime('%FT%T%:z')}+)" }
    assert_equal exp_prop_params, @property_client.build_property_params(:start_at => start_at)
  end

  def test_build_property_params_with_end_at_string
    end_at = "2016-02-13T22:24:35+00:00"
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+),(ModifiedDate=#{end_at}-)" }
    assert_equal exp_prop_params, @property_client.build_property_params(:end_at => end_at)
  end

  def test_build_property_params_with_end_at_time
    end_at = Time.now
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+),(ModifiedDate=#{end_at.utc.strftime('%FT%T%:z')}-)" }
    assert_equal exp_prop_params, @property_client.build_property_params(:end_at => end_at)
  end

  def test_build_property_params_with_start_and_end_at_strings
    start_at = "2016-02-13T22:23:35+00:00"
    end_at = "2016-02-13T22:24:35+00:00"
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+),(ModifiedDate=#{start_at}-#{end_at})" }
    assert_equal exp_prop_params, @property_client.build_property_params(:start_at => start_at, :end_at => end_at)
  end

  def test_build_property_params_with_start_and_end_at_times
    start_at = "2016-02-13T22:23:35+00:00"
    end_at = "2016-02-13T22:24:35+00:00"
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+),(ModifiedDate=#{start_at}-#{end_at})" }
    assert_equal exp_prop_params, @property_client.build_property_params(:start_at => Time.parse(start_at), :end_at => Time.parse(end_at))
  end

  def test_build_property_params_without_time_offsets
    @mls_config.modified_field_accepts_offset = false
    start_at = "2016-02-13T10:23:35-08:00"
    end_at = "2016-02-13T12:11:35-08:00"
    start_at_without_offset = "2016-02-13T18:23:35"
    end_at_without_offset = "2016-02-13T20:11:35"
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT-DECODED", :query => "(ListingID=0+),(ModifiedDate=#{start_at_without_offset}-#{end_at_without_offset})" }
    assert_equal exp_prop_params, @property_client.build_property_params(:start_at => Time.parse(start_at), :end_at => Time.parse(end_at))
  end

  def test_can_override_default_params
    exp_prop_params = { :search_type => "Property", :no_records_not_an_error => true, :class => "RESI", :format => "COMPACT", :query => "(ListingID=0+)" }
    assert_equal exp_prop_params, @property_client.build_property_params(:format => "COMPACT")
  end
end
