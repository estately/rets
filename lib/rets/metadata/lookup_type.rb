module Rets
  module Metadata
    class LookupType
      attr_accessor :long_value, :short_value, :value

      def initialize(lookup_type_fragment)
        self.value       = lookup_type_fragment["Value"]
        self.short_value = lookup_type_fragment["ShortValue"]
        self.long_value  = lookup_type_fragment["LongValue"]
      end

      # Print the tree to a file
      #
      # [out] The file to print to.  Defaults to $stdout.
      def print_tree(out = $stdout)
        out.puts "        #{long_value} -> #{value}"
      end
    end
  end
end
