require 'yaml'
require 'macaddr'
require 'msgpack'

module BitBroker
  ### This object is created for each directory
  class Manager
    WAINTING_TIMEOUT = 5
    CONFIG_PATH = "#{ENV['HOME']}/.bitbroker/config.yml"

    STATE_FINISH = 1<<0
    STATE_WAIT_SUGGESTION = 1<<1
    STATE_WAIT_DATA = 1<<2

    def initialize(opts)
      # set default values
      opts[:config_file] = CONFIG_PATH unless opts[:config_file]

      # validate user created arguments
      validate(opts)

      @dirpath = form_dirpath(opts[:path])
      @config = Config.new({
        :name => opts[:name],
        :config_file => opts[:config_file],
      })

      @metadata = Metadata.new(@dirpath, @config)
    end

    ### initializer to start bitbroker
    def start
      ## construct metadata
      @metadata.advertise

      @pid_metadata_receiver = start_metadata_receiver
    end

    # This methods receives all requested files from remote nodes through AMQP
    def receive_requests files

      suggestions = []
      state = STATE_WAIT_SUGGESTION
      while ! state & STATE_FINISH
        case state
        when STATE_WAIT_SUGGESTION then
          suggestions.push(receive_suggestions)

          verify_suggestion(files, suggestions)
        when STATE_WAIT_DATA then
        end
      end
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
        BitBroker::Subscriber.new(@config).recv_metadata do |data, from|
          ### no implementation yet
          puts "[Manager] (metadata_receiver) #{data} [from: #{from}]"
        end
      end
    end

    def receive_suggestions(timeout=WAINTING_TIMEOUT)
      ret = []

      pid = fork do
        Signal.trap('TERM') do
          raise Exception('TIMEDOUT')
        end
        Subscriber.new(@config).recv_p_metadata do |data, from|
          ret.push(data)
        end
      end

      sleep(timeout)
      Process.kill('TERM', pid)

      ret
    end

    class Config
      attr_reader :name

      def initialize opts
        @name = opts[:name]
        @config = YAML.load_file(opts[:config_file])
      end
      def [](param)
        @config[param]
      end
    end
  end
end
