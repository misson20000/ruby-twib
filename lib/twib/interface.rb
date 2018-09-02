module Twib
  class Interface
    def initialize(connection, device_id, object_id)
      @connection = connection
      @device_id = device_id
      @object_id = object_id

      # object id 0 is special
      #if @object_id != 0 then
      #  ObjectSpace.define_finalizer(self, self.class.finalize(connection, device_id, object_id))
      #end
    end

    def self.finalize(connection, device_id, object_id)
      # send close request
      #connection.send_sync(device_id, object_id, 0xffffffff, String.new)
    end

    def send(command_id, payload=String.new, &block)
      @connection.send(@device_id, @object_id, command_id, payload, &block)
    end
  end
end
