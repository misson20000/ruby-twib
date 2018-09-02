require "socket"
require "thread"

require "twib/version"
require "twib/interfaces/ITwibMetaInterface"
require "twib/interfaces/ITwibDeviceInterface"

module Twib
  class Error < RuntimeError
  end
  
  class ResultError < Error
    def initialize(code)
      super("0x#{code.to_s(16)}")
      @code = code
    end
    attr_reader :code
  end
  
  class Response
    def initialize(device_id, object_id, result_code, tag, payload, object_ids)
      @device_id = device_id
      @object_id = object_id
      @result_code = result_code
      @tag = tag
      @payload = payload
      @object_ids = object_ids
    end

    attr_reader :device_id, :object_id, :result_code, :tag, :payload, :object_ids
    
    def assert_ok
      if @result_code != 0 then
        raise ResultError.new(@result_code)
      end
      return self
    end
  end
  
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

    def respond(response) # expects to be synchronized by @tc.mutex
      @response = response
      @condvar.broadcast
      if @cb then
        @tc.cb_queue.push([@cb, response])
      end
    end

    def wait
      @tc.mutex.synchronize do
        while @response == nil do
          @condvar.wait(@tc.mutex)
        end
      end
      return @response
    end

    def wait_ok
      wait.assert_ok
    end
  end
  
  class TwibConnection
    def self.connect_unix
      return self.new(UNIXSocket.new("/var/run/twibd.sock"))
    end
    
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
          cb.call(response)
        end
      end
    end

    attr_reader :mutex
    attr_reader :cb_queue
    
    def close
      @alive = false
      @socket.close
      @thread.join
    end

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
    
    def list_devices
      @itmi.list_devices
    end

    def open_device(device_id)
      return Interfaces::ITwibDeviceInterface.new(self, device_id, 0)
    end
  end
end
