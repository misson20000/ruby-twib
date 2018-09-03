require "msgpack"

require "twib/interface.rb"

module Twib
  module Interfaces
    # Exposed by twibd
    class ITwibMetaInterface < Interface
      # @api private
      module Command
        LIST_DEVICES = 10
      end

      # Lists devices known to twibd.
      # @return [Array<Hash>]
      def list_devices
        MessagePack.unpack(send(Command::LIST_DEVICES).wait_ok.payload)
      end
    end
  end
end
