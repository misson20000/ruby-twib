require "twib/interface.rb"

require "twib/interfaces/ITwibDebugger.rb"

module Twib
  module Interfaces
    class ITwibDeviceInterface < Interface
      module Command
        RUN = 10
        REBOOT = 11
        COREDUMP = 12
        TERMINATE = 13
        LIST_PROCESSES = 14
        UPGRADE_TWILI = 15
        IDENTIFY = 16
        LIST_NAMED_PIPES = 17
        OPEN_NAMED_PIPE = 18
        OPEN_ACTIVE_DEBUGGER = 19
      end
      def open_active_debugger(pid)
        ITwibDebugger.new(@connection, @device_id, send(Command::OPEN_ACTIVE_DEBUGGER, [pid].pack("Q<")).wait_ok.object_ids[0])
      end
    end
  end
end
