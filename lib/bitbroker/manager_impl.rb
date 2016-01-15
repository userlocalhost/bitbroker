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
      def under_progress?(path)
        ret = false

        check_path = Proc.new do |progress|
          progress.path == path
        end

        ret |= ProgressManager.now_uploadings.any? &check_path
        ret |= ProgressManager.now_downloadings.any? &check_path
      end

      def handle_add(path)
        unless under_progress? path
          Log.debug("[ManagerImpl] (handle_add) actual update :#{path}")

          rpath = @metadata.get_rpath(path)

          # create metadata info
          @metadata.create(rpath)

          # upload target file with backend-thread
          Thread.new do
            Solvant.new(@metadata.dir, rpath).upload(@publisher)
          end

          @metadata.advertise(@publisher)
        end
      end

      def handle_mod(path)
        unless under_progress? path
          Log.debug("[ManagerImpl] (handle_mod) actual update :#{path}")

          rpath = @metadata.get_rpath(path)

          # upload target file with backend-thread
          Thread.new do
            Solvant.new(@metadata.dir, rpath).upload(@publisher)
          end

          # update fileinfo
          @metadata.get_with_path(rpath).update

          @metadata.advertise(@publisher)
        end
      end

      Thread.new do
        Observer.new(@config[:dirpath]) do |mod, add|
          begin
            mod.each {|x| handle_mod(x)}
            add.each {|x| handle_add(x)}
          rescue Exception => e
            Log.dump(e)
          end
        end
      end
    end

    def do_start_collector
      def file_collection
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
      end

      Thread.new do
        loop do
          begin
            file_collection
            Thread.pass
          rescue Exception => e
            Log.dump(e)
          end
        end
      end
    end

    def do_start_metadata_receiver
      Thread.new do
        begin
          receiver = Subscriber.new(@config)
          receiver.recv_metadata do |msg, from|
            case msg['type']
            when Metadata::TYPE_ADVERTISE then
              receive_advertise(msg['data'], from)
            when Metadata::TYPE_REQUEST_ALL then
              receive_request_all(msg['data'], from)
            end
          end
        rescue Exception => e
          Log.dump(e)
        end
      end
    end

    def do_start_p_metadata_receiver
      Thread.new do
        begin
          receiver = Subscriber.new(@config)
          receiver.recv_p_metadata do |msg, from|
            case msg['type']
            when Metadata::TYPE_SUGGESTION then
              receive_suggestion(msg['data'], from)
            when Metadata::TYPE_REQUEST then
              receive_request(msg['data'], from)
            end
          end
        rescue Exception => e
          Log.dump(e)
        end
      end
    end

    def do_start_data_receiver
      Thread.new do
        begin
          receiver = Subscriber.new(@config)
          receiver.recv_data do |binary, from|
            Solvant.load_binary(@config[:dirpath], binary)
          end
        rescue Exception => e
          Log.dump(e)
        end
      end
    end
    def do_start_p_data_receiver
      Thread.new do
        begin
          receiver = Subscriber.new(@config)
          receiver.recv_p_data do |binary, from|
            Solvant.load_binary(@config[:dirpath], binary)
          end
        rescue Exception => e
          Log.dump(e)
        end
      end
    end

    def receive_advertise(data, from)
      def updated?(remote)
        case f = @metadata.get_with_path(remote['path'])
        when nil # this means target file doesn't exist in local.
          true
        else
          f.size != remote['size']
        end
      end
      Log.debug("[ManagerImpl] (receive_advertise) <#{from}> data:#{data}")

      deficients = []
      data.each do |remote|
        if updated? remote
          deficients.push(remote)

          fpath = "#{@config[:dirpath]}/#{remote['path']}"
          if FileTest.exist? fpath
            Log.debug("[ManagerImpl] trancated(#{fpath}, #{remote['size']})")

            # truncate files when target file is cut down
            File.truncate(fpath, remote['size'])
          end
        end
      end

      # request all deficients files
      @metadata.request_all(@publisher, deficients)

      # record deficient files to get it from remote node
      @semaphore.synchronize do
        @deficients += deficients
      end
    end

    def receive_request_all(data, from)
      def has_file?(remote)
        @metadata.get_with_path(remote['path']) != nil
      end
      Log.debug("[ManagerImpl] (receive_request_all) <#{from}> data:#{data}")

      files = data.map {|f| @metadata.get_with_path(f['path'])}.select{|x| x != nil}
      if files != []
        Log.debug("[ManagerImpl] (receive_request_all) files:#{files}")
        @metadata.suggestion(@publisher, files.map{|x| x.to_h}, from)
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
