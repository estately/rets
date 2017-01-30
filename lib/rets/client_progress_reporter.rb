module Rets
  class NullStatsReporter
    def time(metric_name, &block)
      block.call
    end

    def gauge(metric_name, measurement)
    end

    def count(metric_name, count=1)
    end
  end

  class ClientProgressReporter
    def initialize(logger, stats, stats_prefix)
      @logger = logger
      @stats = stats || NullStatsReporter.new
      @stats_prefix = stats_prefix
    end

    def find_with_retries_failed_a_retry(exception, retries, max_retries)
      @stats.count("#{@stats_prefix}find_with_retries_failed_retry")
      @logger.warn("Rets::Client: Failed with message: #{exception.message}")
      @logger.info("Rets::Client: Retry #{retries}/#{max_retries}")
    end

    def find_with_retries_exceeded_retry_count(exception)
      @stats.count("#{@stats_prefix}find_with_retries_exceeded_retry_count")
    end

    def no_records_found
      @logger.info("Rets::Client: No Records Found")
    end

    def could_not_resolve_find_metadata(key)
      @stats.count("#{@stats_prefix}could_not_resolve_find_metadata")
      @logger.warn "Rets::Client: Can't resolve find metadata for #{key.inspect}"
    end

    def use_cached_metadata
      @logger.info "Rets::Client: Use cached metadata"
    end

    def bad_cached_metadata(cached_metadata)
      @logger.info cached_metadata ? "Rets::Client: Cached metadata out of date" : "Rets::Client: Cached metadata unavailable"
    end
  end
end
