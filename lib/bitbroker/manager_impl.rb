module BitBroker
  class ManagerImpl
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
            if candidates.size > 0
              candidate = candidates[rand(candidates.size)]

              @metadata.request(@publisher, [candidate], candidate['from'])

              @semaphore.synchronize do
                @suggestions = @suggestions.reject {|x| x['path'] == deficient['path']}
                @deficients.delete(deficient)
              end
            end
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
        case f = @metadata.getfile_with_path(remote['path'])
        when nil
          true
        else
          f.info.size != remote['size'] and
          f.info.mtime < Time.parse(remote['mtime'])
        end
      end

      deficients = data.select {|f| need_update?(f)}

      @metadata.request_all(@publisher, deficients)
      @semaphore.synchronize do
        @deficients += deficients
      end
    end

    def receive_request_all(data, from)
      def has_file?(remote)
        @metadata.getfile_with_path(remote['path']) != nil
      end

      files = data.map {|f| @metadata.getfile_with_path(f['path'])}.select{|x| x != nil}
      if files != []
        @metadata.suggestion(@publisher, files.map{|x| x.serialize}, from)
      end
    end

    def receive_suggestion(data, from)
      data.each {|x| x['from'] = from}
      @semaphore.synchronize do
        @suggestions += data
      end
    end

    def receive_request(data, from)
      data.each do |msg|
        f = @metadata.getfile_with_path(msg['path'])

        Solvant.new(f.path).upload_to(@publisher, from)
      end
    end
  end
end
