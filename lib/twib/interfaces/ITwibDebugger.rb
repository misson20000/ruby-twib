require "twib/interface.rb"
require "twib/switch/debug.rb"

module Twib
  module Interfaces
    # Debug interface bound to a specific process.
    class ITwibDebugger < Interface
      # @api private
      module Command
        QUERY_MEMORY = 10
        READ_MEMORY = 11
        WRITE_MEMORY = 12
        LIST_THREADS = 13
        GET_DEBUG_EVENT = 14
        GET_THREAD_CONTEXT = 15
        BREAK_PROCESS = 16
        CONTINUE_DEBUG_EVENT = 17
        SET_THREAD_CONTEXT = 18
        GET_NSO_INFOS = 19
        WAIT_EVENT = 20
      end

      # Queries process segment information at the given address.
      #
      #   debug.query_memory(0)
      #   # => {:base=>0, :size=>62308483072, :memory_type=>0,
      #   #     :memory_attribute=>0, :permission=>0,
      #   #     :device_ref_count=>0, :ipc_ref_count=>0}
      #
      # @param addr [Integer] Address to query
      # @return [Hash]
      def query_memory(addr)
        Hash[
          [:base, :size, :memory_type, :memory_attribute,
           :permission, :device_ref_count, :ipc_ref_count].zip(
            send(Command::QUERY_MEMORY, [addr].pack("Q<")).wait_ok.payload.unpack("Q<Q<L<L<L<L<L<"))]
      end

      # Reads from process memory at the given address.
      # @param addr [Integer] Address to read from
      # @param size [Integer] How many bytes to read
      # @return [String]
      def read_memory(addr, size)
        send(Command::READ_MEMORY, [addr, size].pack("Q<Q<")).wait_ok.payload
      end

      # Writes to process memory at the given address.
      # @param addr [Integer] Address to write to
      # @param string [String] Data to write
      # @return [String]
      def write_memory(addr, string)
        send(Command::WRITE_MEMORY, [addr].pack("Q<") + string).wait_ok
        string
      end

      # Lists threads in the target process.
      # @return [self]
      def list_threads
        raise "nyi"
      end

      # Gets a debug event from the target process.
      # @return [Switch::Debug::Event, nil] A debug event, or nil if none were left
      def get_debug_event
        rs = send(Command::GET_DEBUG_EVENT).wait
        if rs.result_code == 0x8c01 then # no debug events left
          return nil
        else
          rs.assert_ok
        end
        return Switch::Debug::Event::Event.unpack(rs.payload)
      end

      # Gets a thread's context.
      # @return [String]
      def get_thread_context(thread_id)
        send(Command::GET_THREAD_CONTEXT, [thread_id].pack("Q<")).wait_ok.payload
      end

      # Breaks the target process.
      # @return [self]
      def break_process
        raise "nyi"
      end

      # Continues the target process.
      # @param flags [Integer] See http://www.switchbrew.org/index.php?title=SVC#ContinueDebugFlagsOld
      # @return [self]
      def continue_debug_event(flags, thread_ids=[])
        send(Command::CONTINUE_DEBUG_EVENT, ([flags] + thread_ids).pack("L<Q<*")).wait_ok
        self
      end

      # Sets a thread's context.
      # @return [self]
      def set_thread_context(thread_id)
        raise "nyi"
      end

      # Queries NSO info for the target process.
      # @return [Array<Hash>]
      def get_nso_infos
        response = send(Command::GET_NSO_INFOS).wait_ok.payload
        count = response.unpack("Q<")[0]
        count.times.map do |i|
          Hash[
            [:base, :size, :build_id].zip(response[8 + 0x30 * i, 0x30].unpack("Q<Q<a32"))]
        end
      end

      # Yields from a separate thread when a debug event is available.
      # @return [self]
      def wait_event_async(&block)
        send(Command::WAIT_EVENT, String.new, &block)
        self
      end

      # Waits for a debug event to become available.
      # @return [self]
      def wait_event
        send(Command::WAIT_EVENT).wait_ok
        self
      end
    end
  end
end
