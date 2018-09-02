require "twib/interface.rb"
require "twib/switch/debug.rb"

module Twib
  module Interfaces
    class ITwibDebugger < Interface
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
      
      def query_memory(addr)
        Hash[
          [:base, :size, :memory_type, :memory_attribute,
           :permission, :device_ref_count, :ipc_ref_count].zip(
            send(Command::QUERY_MEMORY, [addr].pack("Q<")).wait_ok.payload.unpack("Q<Q<L<L<L<L<L<"))]
      end
      
      def read_memory(addr, size)
        send(Command::READ_MEMORY, [addr, size].pack("Q<Q<")).wait_ok.payload
      end
      
      def write_memory(addr, string)
        send(Command::WRITE_MEMORY, [addr].pack("Q<") + string).wait_ok
      end
      
      def list_threads
        raise "nyi"
      end
      
      def get_debug_event
        rs = send(Command::GET_DEBUG_EVENT).wait
        if rs.result_code == 0x8c01 then # no debug events left
          return nil
        end
        return Switch::Debug::Event::Event.unpack(rs.payload)
      end
      
      def get_thread_context(thread_id)
        raise "nyi"
      end
      
      def break_process
        raise "nyi"
      end
      
      def continue_debug_event(flags, thread_ids=[])
        send(Command::CONTINUE_DEBUG_EVENT, ([flags] + thread_ids).pack("L<Q<*")).wait_ok
        nil
      end
      
      def set_thread_context(thread_id)
        raise "nyi"
      end
      
      def get_nso_infos
        response = send(Command::GET_NSO_INFOS).wait_ok.payload
        count = response.unpack("Q<")[0]
        count.times.map do |i|
          Hash[
            [:base, :size, :build_id].zip(response[8 + 0x30 * i, 0x30].unpack("Q<Q<a32"))]
        end
      end
      
      def wait_event_async(&block)
        send(Command::WAIT_EVENT, String.new, &block)
      end
      
      def wait_event
        send(Command::WAIT_EVENT).wait_ok
      end
    end
  end
end
