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
        response = send(Command::LIST_DEVICES).wait_ok.payload
        size = response.unpack("Q<")[0]
        MessagePack.unpack(response[8, size])
      end
    end
  end
end
