module Rets
  class LockingCookieSaver < HTTPClient::WebAgentSaver
    def save(io, jar)
      io.flock(File::LOCK_EX) if io.respond_to?(:flock)
      super
    end

    def load(io, jar)
      io.flock(File::LOCK_SH) if io.respond_to?(:flock)
      super
    end
  end
end