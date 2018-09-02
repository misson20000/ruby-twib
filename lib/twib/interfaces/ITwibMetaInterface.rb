require "msgpack"

require "twib/interface.rb"

module Twib
  module Interfaces
    class ITwibMetaInterface < Interface
      module Command
        LIST_DEVICES = 10
      end
      def list_devices
        MessagePack.unpack(send(Command::LIST_DEVICES).wait_ok.payload)
      end
    end
  end
end
