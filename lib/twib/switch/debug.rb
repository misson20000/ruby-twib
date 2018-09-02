module Twib
  module Switch
    module Debug
      module Event
        class Event
          def self.unpack(pack)
            event_type, flags, thread_id, specific = pack.unpack("L<L<Q<a*")
            case event_type
            when AttachProcess::TYPE
              return AttachProcess.new(flags, thread_id, specific)
            when AttachThread::TYPE
              return AttachThread.new(flags, thread_id, specific)
            when ExitProcess::TYPE
              return ExitProcess.new(flags, thread_id, specific)
            when ExitThread::TYPE
              return ExitThread.new(flags, thread_id, specific)
            when Exception::TYPE
              return Exception.new(flags, thread_id, specific)
            else
              raise "unknown debug event type: #{event_type}"
            end
          end
          def initialize(flags, thread_id, specific)
            @flags = flags
            @thread_id = thread_id
            unpack_specific(specific)
          end
          attr_reader :flags
          attr_reader :thread_id
        end
        
        class AttachProcess < Event
          TYPE = 0
          def unpack_specific(pack)
            @title_id, @process_id, @process_name, @mmu_flags = pack.unpack("Q<Q<Z12L<")
          end
          def event_type
            :attach_process
          end
          attr_reader :title_id, :process_id, :process_name, :mmu_flags
        end
        
        class AttachThread < Event
          TYPE = 1
          def unpack_specific(pack)
            @thread_id, @tls, @entrypoint = pack.unpack("Q<Q<Q<")
          end
          def event_type
            :attach_thread
          end
          attr_reader :thread_id, :tls, :entrypoint
        end
        
        class ExitProcess < Event
          TYPE = 2
          def unpack_specific(pack)
            @type = pack.unpack("L<")
          end
          def event_type
            :exit_process
          end
          attr_reader :type
        end
        
        class ExitThread < Event
          TYPE = 3
          def unpack_specific(pack)
            @type = pack.unpack("L<")
          end
          def event_type
            :exit_thread
          end
          attr_reader :type
        end
        
        class Exception < Event
          TYPE = 4
          def unpack_specific(pack)
            @type, @fault_register, @specific = pack.unpack("L<Q<a*")
          end
          def event_type
            :exception
          end
          attr_reader :type, :fault_register, :specific
        end
      end
    end
  end
end
