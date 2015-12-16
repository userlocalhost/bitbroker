module BitBroker
  class ManagerImpl
    WAINTING_TIMEOUT = 5

    STATE_FINISH = 1<<0
    STATE_WAIT_SUGGESTION = 1<<1
    STATE_WAIT_DATA = 1<<2

    COLLECTION_DELAY = 3

    def initialize(opts)
      # validate user created arguments
      validate(opts)

      @metadata = Metadata.new(form_dirpath(opts[:path]))

      ### prepare brokers
      @config = {
        :mqconfig => opts[:mqconfig],
        :label => opts[:name],
      }

      @publisher = Publisher.new(@config)

      @deficients = @suggestions = []
      @semaphore = Mutex.new
    end

    def form_dirpath path
        path[-1] == '/' ? form_dirpath(path.chop) : path
    end
    def validate(opts)
      raise InvalidArgument("Specified path is not directory") unless File.directory?(opts[:path])
    end

    def do_start_collector
      Thread.new do
        loop do
          deficient = @deficients.first
          if deficient != nil
            candidates = @suggestions.select { |x| x['path'] == deficient['path'] }
          end

          Thread.pass
        end
      end
    end

    def do_start_metadata_receiver
      Thread.new do
        receiver = Subscriber.new(@config)
        receiver.recv_metadata do |msg, from|
          case msg['type']
          when Metadata::TYPE_ADVERTISE then
            receive_advertise(msg['data'], from)
          when Metadata::TYPE_REQUEST_ALL then
            receive_request_all(msg['data'], from)
          end
        end
      end
    end

    def do_start_p_metadata_receiver
      Thread.new do
        receiver = Subscriber.new(@config)
        receiver.recv_p_metadata do |msg, from|
          case msg['type']
          when Metadata::TYPE_SUGGESTION then
            receive_suggestion(msg['data'], from)
          when Metadata::TYPE_REQUEST then
            receive_request(msg['data'], from)
          end
        end
      end
    end

    def receive_advertise(data, from)
      def need_update?(remote)
        case f = @metadata.getfile_with_rpath(remote['path']).first
        when nil
          true
        else
          f.info.size != remote['size'] and
          f.info.mtime < Time.parse(remote['mtime'])
        end
      end

      deficients = data.select {|f| need_update?(f)}

      @metadata.request_all(@publisher, deficients)
      @semaphore.synchronize {
        @deficients += deficients
      }
    end

    def receive_request_all(data, from)
      def has_file?(remote)
        @metadata.getfile_with_rpath(remote['path']).first != nil
      end

      files = data.map {|f| @metadata.getfile_with_rpath(f['path']).first}.select{|x| x != nil}

      if files != []
        @metadata.suggestion(@publisher, files.map{|x| x.serialize}, from)
      end
    end

    def receive_suggestion(data, from)
      data.each {|x| x['from'] = from}
      @semaphore.synchronize {
        @suggestions += data
      }
    end

    def receive_request(data, from)
      data.each do |f|
        Solvant.new(f['path']).upload_to(@publisher, from)
      end
    end
  end
end
