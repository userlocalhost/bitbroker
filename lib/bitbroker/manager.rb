require 'yaml'
require 'macaddr'
require 'msgpack'

module BitBroker
  ### This object is created for each directory
  class Manager
    RKEY_DATA = 'data'
    RKEY_METADATA = 'metadata'

    WAINTING_TIMEOUT = 5
    CONFIG_PATH = "#{ENV['HOME']}/.bitbroker/config.yml"

    STATE_FINISH = 1<<0
    STATE_WAIT_SUGGESTION = 1<<1
    STATE_WAIT_DATA = 1<<2

    def self.mqconfig
      config = YAML.load_file(CONFIG_PATH)['mqconfig']
      config['prkey_metadata'] = Mac.addr + 'metadata'

      config
    end

    def initialize(opts)
      validate(opts)

      @namelabel = opts[:name]
      @dirpath = form_dirpath(opts[:path])

      @metadata = Metadata.new(@dirpath, @namelabel)
    end

    ### initializer to start bitbroker
    def start
      @pid_metadata_receiver = start_metadata_receiver

      ## construct metadata
      @metadata.advertise
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
    end

    def start_metadata_receiver
      fork do
        BitBroker::Subscriber.new(@namelabel).receive(RKEY_METADATA) do |data|
          ### no implementation yet
        end
      end
    end

    def receive_suggestions(timeout=WAINTING_TIMEOUT)
      conf = Manager.mqconfig['prkey_metadata']
      ret = []

      pid = fork do
        Signal.trap('TERM') do
          raise Exception('TIMEDOUT')
        end
        Subscriber.new(@namelabel).receive(conf['prkey_metadata']) do |data|
          ret.push(data)
        end
      end

      sleep(timeout)
      Process.kill('TERM', pid)

      ret
    end
  end
end
