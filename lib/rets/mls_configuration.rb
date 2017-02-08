module Rets
  class MlsConfiguration
    PROPERTY_RESOURCE_TYPE = 'Property'.freeze

    attr_accessor :mls, :property_key_field, :property_class,
      :property_key_field_numeric, :property_resource_type, :client_params,
      :property_resource_type, :property_modified_key_field, :modified_field_accepts_offset

    def client_params
      @client_params || {}
    end

    def property_resource_type
      @property_resource_type || PROPERTY_RESOURCE_TYPE
    end

    def property_key_field_numeric?
      @property_key_field_numeric.nil? ? true : @property_key_field_numeric
    end

    def modified_field_accepts_offset?
      @modified_field_accepts_offset.nil? ? true : modified_field_accepts_offset
    end
  end
end
