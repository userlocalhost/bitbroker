module BitBroker
  class ManagerImpl
    def initialize(opts)
      # validate user created arguments
      validate(opts)

      ### prepare brokers
      @config = {
        :mqconfig => opts[:mqconfig],
        :label => opts[:name],
        :dirpath => form_dirpath(opts[:path]),
      }

      @metadata = Metadata.new(@config[:dirpath])

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

    def do_start_observer
      def handle_add(path)
        Log.debug("[ManagerImpl] (handle_add) path:#{path}")

        rpath = @metadata.get_rpath(path)

        # create metadata info
        @metadata.create(rpath)

        # upload target file
        Solvant.new(@metadata.dir, rpath).upload(@publisher)
      end

      def handle_mod(path)
        Log.debug("[ManagerImpl] (handle_mod) path:#{path}")

        rpath = @metadata.get_rpath(path)

        # upload target file
        Solvant.new(@metadata.dir, rpath).upload(@publisher)
      end

      def handle_rem(path)
        Log.debug("[ManagerImpl] (handle_rem) path:#{path}")

        rpath = @metadata.get_rpath(path)

        #@metadata.remove_with_path(rpath)
        file = @metadata.get_with_path(rpath)

        file.remove

        @metadata.advertise(@publisher)
      end

      Thread.new do
        Observer.new(@config[:dirpath]) do |mod, add, rem|
          mod.each {|x| handle_mod(x)}
          add.each {|x| handle_add(x)}
          rem.each {|x| handle_rem(x)}
        end
      end
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

    def do_start_data_receiver
      Thread.new do
        receiver = Subscriber.new(@config)
        receiver.recv_data do |binary, from|
          Solvant.load_binary(@config[:dirpath], binary)
        end
      end
    end
    def do_start_p_data_receiver
      Thread.new do
        receiver = Subscriber.new(@config)
        receiver.recv_p_data do |binary, from|
          Solvant.load_binary(@config[:dirpath], binary)
        end
      end
    end

    def receive_advertise(data, from)
      def need_update?(remote)
        case f = @metadata.get_with_path(remote['path'])
        when nil # this means target file doesn't exist in local.
          true
        else
          f.info.size != remote['size'] and
          f.info.mtime < Time.parse(remote['mtime']) and
          not f.removed?
        end
      end

      def removed?(remote)
        case f = @metadata.get_with_path(remote['path'])
        when nil
          false
        else
          remote['status'].to_i & Metadata::FileInfo::STATUS_REMOVED > 0
        end
      end
      Log.debug("[ManagerImpl] (receive_advertise) <#{from}> data:#{data}")

      # processing for deficient files
      deficients = data.select {|f| need_update?(f)}

      @metadata.request_all(@publisher, deficients)
      @semaphore.synchronize do
        @deficients += deficients
      end

      # processing for removed files
      data.select{|f| removed?(f)}.each do |remote|
        Log.debug("[ManagerImpl] (receive_advertise) remove: #{remote}")

        # remove FileInfo object which metadata has
        @metadata.remove_with_path(remote['path'])

        # remove actual file in local FS
        Solvant.new(@config[:dirpath], remote['path']).remove
      end
    end

    def receive_request_all(data, from)
      def has_file?(remote)
        @metadata.get_with_path(remote['path']) != nil
      end
      Log.debug("[ManagerImpl] (receive_request_all) <#{from}> data:#{data}")

      files = data.map {|f| @metadata.get_with_path(f['path'])}.select{|x| x != nil}
      if files != []
        @metadata.suggestion(@publisher, files.map{|x| x.serialize}, from)
      end
    end

    def receive_suggestion(data, from)
      Log.debug("[ManagerImpl] (receive_suggestion) <#{from}> data:#{data}")

      data.each {|x| x['from'] = from}
      @semaphore.synchronize do
        @suggestions += data
      end
    end

    def receive_request(data, from)
      Log.debug("[ManagerImpl] (receive_request) <#{from}> data:#{data}")

      data.each do |remote|
        f = @metadata.get_with_path(remote['path'])

        Solvant.new(@config[:dirpath], f.path).upload_to(@publisher, from)
      end
    end
  end
end
