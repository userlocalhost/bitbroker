require 'msgpack'

module BitBroker
  class ProgressManager
    SEMAPHORE = Mutex.new

    def self.uploading(opts = nil)
      container = Container.new
      if opts == nil
        container.uploading
      else
        self.update_progress(opts, container.uploading)
        container.save
      end
    end
    def self.downloading(opts = nil)
      container = Container.new
      if opts == nil
        container.downloading
      else
        self.update_progress(opts, container.downloading)
        container.save
      end
    end

    private
    def self.update_progress(opts, container)
      progress = container.find {|x| x.path == opts[:path]}
      if progress == nil
        progress = Progress.new(opts)

        # append class variables
        container.push(progress)
      end

      progress.update(opts[:offset])
    end

    class Container
      attr_reader :uploading, :downloading

      def initialize
        def fileload(path, container)
          SEMAPHORE.synchronize do
            if FileTest.exist? path
              MessagePack.unpack(File.read(path)).each do |data|
                progress = container.find {|x| x.path == data['path']}
                if progress == nil
                  container.push(BitBroker::ProgressManager::Progress.new({
                    :path => data['path'],
                    :bitmap => data['bitmap'],
                    :fullsize => data['fullsize'],
                    :chunk_size => data['chunk_size'],
                  }))
                end
              end
            end
          end
        end

        @uploading = []
        @downloading = []
        fileload(BitBroker::Config::PATH_UPLOADING, @uploading)
        fileload(BitBroker::Config::PATH_DOWNLOADING, @downloading)
      end
      def save
        SEMAPHORE.synchronize do
          File.write(BitBroker::Config::PATH_UPLOADING, MessagePack.pack(@uploading.map{|x| x.serialize}))
          File.write(BitBroker::Config::PATH_DOWNLOADING, MessagePack.pack(@downloading.map{|x| x.serialize}))
        end
      end
    end

    # This describes 
    class Progress
      attr_reader :path, :last_update

      def initialize(opts)
        length = opts[:fullsize] / opts[:chunk_size]
        length += 1 if opts[:fullsize] % opts[:chunk_size] > 0

        @chunk_size = opts[:chunk_size]
        @fullsize = opts[:fullsize]
        @path = opts[:path]
        @last_update = Time.now

        @bitmap = opts[:bitmap]
        @bitmap = Array.new(length, false) unless !!@bitmap
      end
      def update(index)
        @bitmap[index] = true
        @last_update = Time.now
      end
      def progress
        # return progress percentage
        100 * @bitmap.select{|x| x}.size / @bitmap.size
      end
      def serialize
        {'path' => @path, 'bitmap' => @bitmap, 'chunk_size' => @chunk_size, 'fullsize' => @fullsize}
      end
      def to_s
        # return progress status string
        "[ %2d%% ] #{@path}" % progress
      end
    end
  end
end
