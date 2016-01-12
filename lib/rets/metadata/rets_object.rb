module Rets
  module Metadata
    class RetsObject
      attr_reader :name, :mime_type, :description

      def initialize(name, mime_type, description)
        @name = name
        @mime_type = mime_type
        @description = description
      end

      def self.build(rets_object_fragment)
        name = rets_object_fragment["VisibleName"]
        mime_type = rets_object_fragment["MIMEType"]
        description = rets_object_fragment["Description"]
        new(name, mime_type, description)
      end

      def print_tree(out = $stdout)
        out.puts "  Object: #{name}"
        out.puts "    MimeType: #{mime_type}"
        out.puts "    Description: #{description}"
      end

      def ==(other)
        name == other.name &&
          mime_type == other.mime_type &&
          description == other.description
      end
    end
  end
end
