require 'yaml'
require 'macaddr'
require 'msgpack'
require 'time'

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

      @metadata = Metadata.new( form_dirpath(opts[:path]))

      ### prepare brokers
      config = {
        :mqconfig => opts[:mqconfig],
        :label => opts[:name],
      }
      @publisher = Publisher.new(config)
      @subscriber = Subscriber.new(config)
    end

    def advertise
      @metadata.advertise(@publisher)
    end

    def start_metadata_receiver
      @pid_metadata_receiver = do_start_metadata_receiver
    end

    def stop_metadata_receiver
      Process.kill('TERM', @pid_metadata_receiver)
    end

    private
    def form_dirpath path
        path[-1] == '/' ? form_dirpath(path.chop) : path
    end
    def validate opts
      raise InvalidArgument("Specified path is not directory") unless File.directory?(opts[:path])
    end

    def do_start_metadata_receiver
      fork do
        @subscriber.recv_metadata do |data, from|
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
      def need_update?(remote)
        case f = @metadata.get_file(remote['path']).first
        when nil
          true
        else
          f.info.size != remote['size'] and
          f.info.mtime < Time.parse(remote['mtime'])
        end
      end

      @metadata.request_all(@publisher, data.select {|f| will_update?(f)})
    end

    def receive_request_all(data, from)
      def has_file?(remote)
        @metadata.get_file(remote['path']).fist != nil
      end

      files = data.map {|f| @metadata.get_file(f['path']).first}.select{|x| x != nil}
      @metadata.suggestion(@publisher, files.map{|x| x.serialize}, from)
    end

    def receive_suggestion(data, from)
      @suggestions = data.map {|x| x['from'] = from}
    end

    def receive_request(data, from)
      data.each do |f|
        Solvant.new(f['path']).upload_to(@publisher, from)
      end
    end
  end
end
