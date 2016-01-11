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

          manager = BitBroker::Manager.new({
            :mqconfig => BitBroker::Config['mqconfig'],
            :path => entry['path'],
            :name => entry['name'],
          })

          manager.start
          manager.advertise

          manager.join
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
      @threads = []

      # start observer that watches changing of local file-system
      @threads << do_start_observer

      # start receivers that consume message of remote nodes
      @threads << do_start_metadata_receiver
      @threads << do_start_p_metadata_receiver

      @threads << do_start_data_receiver
      @threads << do_start_p_data_receiver

      # start collector that maintains the shared directory will be same with remote ones.
      @threads << do_start_collector

      @threads.each {|t| t.abort_on_exception = true}
    end

    def join
      @threads.each(&:join)
    end

    def stop
      # for observer
      @threads.each do |t|
        t.raise 'stop'
      end
    end
  end
end
