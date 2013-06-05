module Rets
  class LockingClient
    def initialize(client, locker, lock_name)
      @client = client
      @locker = locker
      @lock_name = lock_name
    end

    def method_missing(method_name, *args, &block)
      result = nil
      @locker.lock(@lock_name) do
        result = @client.send(method_name, *args, &block)
      end
      result
    end
  end
end
