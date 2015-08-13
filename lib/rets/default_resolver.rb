module Rets
  class DefaultResolver
    attr_reader :client_progress

    def resolve(results, rets_class, client_progress)
      results.map do |result|
        decorate_result(result, rets_class)
      end
    end

    def decorate_result(result, rets_class, client_progress)
      result.each do |key, value|
        table = rets_class.find_table(key)
        if table
          result[key] = table.resolve(value.to_s)
        else
          #can't resolve just leave the value be
          client_progress.could_not_resolve_find_metadata(key)
        end
      end
    end
  end
end
