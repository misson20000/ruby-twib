require "socket"
require "thread"

require "twib/version"
require "twib/interfaces/ITwibMetaInterface"
require "twib/interfaces/ITwibDeviceInterface"

module Twib
  class Error < RuntimeError
  end

  # An error originating from either twibd or a remote device.
  class ResultError < Error
    def initialize(code)
      super("0x#{code.to_i.to_s(16)}")
      @code = code.to_i
    end

    # @return [Integer] the bad result code that caused this error
    attr_reader :code
  end

  # A response from either twibd or a remote device.
  class Response
    # @param device_id [Integer] ID of the device that this response originated from.
    # @param object_id [Integer] ID of the bridge object that this response originated from.
    # @param result_code [Integer] Result code
    # @param tag [Integer] Tag corresponding to the request that prompted this response.
    # @param payload [String] Raw data associated with the response
    # @param object_ids [Array<Integer>] Object IDs sent with the response
    def initialize(device_id, object_id, result_code, tag, payload, object_ids)
      @device_id = device_id
      @object_id = object_id
      @result_code = result_code
      @tag = tag
      @payload = payload
      @object_ids = object_ids
    end

    attr_reader :device_id, :object_id, :result_code, :tag, :payload, :object_ids

    # Raises a {ResultError} if the {#result_code} is not OK.
    # @raise [ResultError]
    # @return [self]
    def assert_ok
      if @result_code != 0 then
        raise ResultError.new(@result_code)
      end
      return self
    end
  end

  # A request to be sent to a remote device.
  class ActiveRequest
    def initialize(tc, device_id, object_id, command_id, tag, payload, &block)
      @tc = tc
      @device_id = device_id
      @object_id = object_id
      @command_id = command_id
      @tag = tag
      @payload = payload
      @condvar = ConditionVariable.new
      @cb = block
      @response = nil
    end

    # @api private
    def respond(response) # expects to be synchronized by @tc.mutex
      @response = response
      @condvar.broadcast
      if @cb then
        @tc.cb_queue.push([@cb, response])
      end
    end

    # Waits for this request to receive a response.
    # @return [Response]
    def wait
      @tc.mutex.synchronize do
        while @response == nil do
          @condvar.wait(@tc.mutex)
        end
      end
      return @response
    end

    # Waits for this request to receive a response, and raises if the response is not OK.
    # @raise [ResultError]
    # @return [Response]
    def wait_ok
      wait.assert_ok
    end
  end

  # A connection to twibd.
  class TwibConnection
    # Connects to twibd using the standard UNIX socket address.
    # @return [TwibConnection]
    def self.connect_unix
      return self.new(UNIXSocket.new("/var/run/twibd.sock"))
    end

    # Creates a TwibConnection using the specified socket
    # @param [BasicSocket] socket
    def initialize(socket)
      @socket = socket
      @itmi = Interfaces::ITwibMetaInterface.new(self, 0, 0)
      @alive = true
      @active_requests = {}
      @mutex = Mutex.new
      @thread = Thread.new do
        loop do
          header = @socket.recv(32)
          header = header.unpack("L<L<L<L<Q<L<")
          
          payload = String.new
          object_ids = []
          if header[4] > 0 then
            payload = @socket.recv(header[4]) # payload size
          end
          if header[5] > 0 then
            object_ids = @socket.recv(header[5] * 4).unpack("L<*") # object IDs
          end

          rs = Response.new(header[0], header[1], header[2], header[3], payload, object_ids)
          @mutex.synchronize do
            rq = @active_requests.delete(rs.tag)
            if !rq then
              puts "WARNING: got response for bad tag"
            end
            rq.respond(rs)
          end
        end
      end

      @cb_queue = Queue.new
      @cb_thread = Thread.new do # to avoid deadlocks on I/O thread, we execute callbacks here
        while @alive do
          cb, response = @cb_queue.pop
          if cb then
            cb.call(response)
          end
        end
      end
    end

    # @api private
    attr_reader :mutex
    # @api private
    attr_reader :cb_queue

    # Closes the socket and stops internal threads
    def close
      @alive = false
      @socket.close
      @thread.join
      @cb_queue.close
      @cb_thread.join
    end

    # @api private
    # @return [ActiveRequest]
    def send(device_id, object_id, command_id, payload, &block)
      tag = rand(0xffffffff)

      rq = ActiveRequest.new(self, device_id, object_id, command_id, tag, payload, &block)
      @active_requests[tag] = rq
      
      message = [device_id, object_id, command_id, tag, payload.size, 0, 0].pack("L<L<L<L<Q<L<L<") + payload
      sz = @socket.send(message, 0)
      if sz < message.size then
        raise "couldn't send entire message"
      end

      return rq
    end

    # Returns a list of devices connected to twibd.
    #
    #   tc.list_devices
    #   # => [{"device_id"=>507914862, "identification"=>{...}}]
    #
    # Use {#open_device} to connect to one.
    #
    # @return [Array<Hash>]
    def list_devices
      @itmi.list_devices
    end

    # Opens a device specified by one of the device IDs returned from {#list_devices}.
    # @return [Interfaces::ITwibDeviceInterface]
    def open_device(device_id)
      return Interfaces::ITwibDeviceInterface.new(self, device_id, 0)
    end
  end
end
