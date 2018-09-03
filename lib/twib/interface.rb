module Twib
  # Base class for Ruby bindings to a remote interface.
  # An instance of this class represents a remote bridge object.
  #
  # This class and any subclasses should not typically be instantiated directly.
  # Rather, instances should be returned from either {TwibConnection#open_device}
  # or a remote command binding.
  class Interface
    
    # @param connection [TwibConnection] Twib connection to use for transport
    # @param device_id [Integer] ID of the device this object exists on
    # @param object_id [Integer] ID of the remote object this object is bound to
    def initialize(connection, device_id, object_id)
      @connection = connection
      @device_id = device_id
      @object_id = object_id
    end

    # Sends a request to the remote object this instance is bound to.
    #
    #   object.send(10, [1234].pack("L<")) do |rs|
    #     puts "got back: " + rs.assert_ok.payload
    #   end
    #
    #   object.send(10, [1234].pack("L<")).wait_ok
    #   # => #<Twib::TwibConnection::Response>
    #
    # @param command_id [Integer] ID of remtoe command to invoke
    # @param payload [String] Data to send along with the request
    # @yield [rs] Calls the block (in a separate thread) when a response is received, if present.
    # @yieldparam rs [Response]
    # @return [ActiveRequest]
    def send(command_id, payload=String.new, &block)
      @connection.send(@device_id, @object_id, command_id, payload, &block)
    end
  end
end
