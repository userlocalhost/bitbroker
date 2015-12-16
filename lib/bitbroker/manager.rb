require 'yaml'
require 'macaddr'
require 'msgpack'
require 'time'
require 'thread'

require 'bitbroker/manager_impl'

module BitBroker
  ### This object is created for each directory
  class Manager < ManagerImpl

    def initialize(opts)
      super(opts)
    end

    def advertise
      @metadata.advertise(@publisher)
    end

    def start_receiver
      @metadata_receiver = do_start_metadata_receiver
      @p_metadata_receiver = do_start_p_metadata_receiver
    end

    def stop_receiver
      @metadata_receiver.raise "stop"
      @metadata_receiver.join

      @p_metadata_receiver.raise "stop"
      @p_metadata_receiver.join
    end

    def start_collector
      @collector = do_start_collector
    end
    def stop_collector
      @collector.kill
    end
  end
end
