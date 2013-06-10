module Rets
  class LockingClient
    def initialize(client, locker, lock_name, options={})
      @client = client
      @locker = locker
      @lock_name = lock_name
      @options = {}
    end

    def method_missing(method_name, *args, &block)
      result = nil
      @locker.lock(@lock_name, @options) do
        result = @client.send(method_name, *args, &block)
      end
      result
    end
  end
end
