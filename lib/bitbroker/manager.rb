require 'yaml'
require 'macaddr'
require 'msgpack'

module BitBroker
  ### This object is created for each directory
  class Manager
    WAINTING_TIMEOUT = 5

    STATE_FINISH = 1<<0
    STATE_WAIT_SUGGESTION = 1<<1
    STATE_WAIT_DATA = 1<<2

    def initialize(opts)
      # validate user created arguments
      validate(opts)

      @metadata = Metadata.new(@dirpath)

      ### prepare brokers
      config = {
        :mqconfig => opts[:mqconfig],
        :label => opts[:name],
      }
      @publisher = Publisher.new(config)
      @subscriber = Subscriber.new(config)
    end

    ### initializer to start bitbroker
    def start
      ## construct metadata
      @metadata.advertise(@publisher)

      @pid_metadata_receiver = start_metadata_receiver
    end

    private
    def form_dirpath path
        path[-1] == '/' ? form_dirpath(path.chop) : path
    end
    def validate opts
      raise InvalidArgument("Specified path is not directory") unless File.directory?(opts[:path])
      raise InvalidArgument("invalid config file") unless File.exist?(opts[:config_file])
    end

    def start_metadata_receiver
      fork do
        @subscriber.recv_metadata do |data, from|
          ### no implementation yet
          puts "[Manager] (metadata_receiver) #{data} [from: #{from}]"

          case data['type']
          when Metadata::TYPE_ADVERTISE then
            receive_advertise(data, from)
          when Metadata::TYPE_REQUEST_ALL then
            receive_request_all(data, from)
          when Metadata::TYPE_SUGGESTION then
            receive_suggestion(data, from)
          when Metadata::TYPE_REQEUST then
            receive_request(data, from)
          end
        end
      end
    end

    def receive_advertise(data, from)
    end

    def receive_request_all(data, from)
    end

    def receive_suggestion(data, from)
    end

    def receive_request(data, from)
    end
  end
end
