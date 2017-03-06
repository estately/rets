module Rets
  class LockingCookieSaver < HTTPClient::WebAgentSaver
    def save(io, jar)
      Timeout::timeout(lock_timeout) { io.flock(File::LOCK_EX) } if io.respond_to?(:flock)
      super
    end

    def load(io, jar)
      Timeout::timeout(lock_timeout) { io.flock(File::LOCK_SH) } if io.respond_to?(:flock)
      super
    end

    private

    def lock_timeout
      1
    end
  end
end
