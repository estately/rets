module Rets
  class ClientProgressReporter
    def initialize(logger)
      @logger = logger
    end

    def find_with_retries_failed_a_retry(exception, retries)
      @logger.warn("Rets::Client: Failed with message: #{exception.message}")
      @logger.info("Rets::Client: Retry #{retries}/3")
    end

    def find_with_retries_exceeded_retry_count(exception)
    end

    def could_not_resolve_find_metadata(key)
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
