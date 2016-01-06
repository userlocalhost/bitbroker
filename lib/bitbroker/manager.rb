require 'yaml'
require 'macaddr'
require 'msgpack'
require 'time'
require 'thread'

require 'bitbroker/manager_impl'

module BitBroker
  ### This object is created for each directory
  class Manager < ManagerImpl

    def self.start
      BitBroker::Config['directories'].each do |entry|
        fork do
          Process.daemon
          File.open(PIDFILE, 'a') do |f|
            f.write("#{$$}\n")
          end

          begin
            manager = BitBroker::Manager.new({
              :mqconfig => BitBroker::Config['mqconfig'],
              :path => entry['path'],
              :name => entry['name'],
            })

            manager.start
            manager.advertise

            loop {}
          rescue Exception => e
            Log.error(e.to_s)
            manager.stop
            raise e
          end
        end
      end
    end

    def initialize(opts)
      super(opts)
    end

    def advertise
      @metadata.advertise(@publisher)
    end

    def start
      # start observer that watches changing of local file-system
      @observer = do_start_observer

      # start receivers that consume message of remote nodes
      @metadata_receiver = do_start_metadata_receiver
      @p_metadata_receiver = do_start_p_metadata_receiver

      @data_receiver = do_start_data_receiver
      @p_data_receiver = do_start_p_data_receiver

      # start collector that maintains the shared directory will be same with remote ones.
      @collector = do_start_collector
    end

    def stop
      # for observer
      @observer.raise 'stop'
      @observer.join

      # for receiver
      @metadata_receiver.raise "stop"
      @metadata_receiver.join

      @p_metadata_receiver.raise "stop"
      @p_metadata_receiver.join

      @data_receiver.raise "stop"
      @data_receiver.join

      @p_data_receiver.raise "stop"
      @p_data_receiver.join

      # for collector
      @collector.kill
    end
  end
end
