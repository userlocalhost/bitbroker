require 'leveldb'

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
      # create progress object
      data = container[opts[:path]]
      progress = data != nil ? Progress.new(data) : Progress.new(opts)

      # update progress bitmap
      progress.update(opts[:offset])

      # save progress infomation to the database
      container[opts[:path]] = progress.serialize
    end

    class Container
      def initialize(type)
        @db = LeelDB::DB.new BitBroker::Config::PATH_PROGRESSINFO
        @db[type] ||= {}

        @type = type
      end
      def [](path)
        @db[@type][path]
      end
      def []=(path, data)
        @db[@type][path] = data
      end
    end
    class UploadInfo < Container
      def initialize
        super(:uploading)
      end
    end
    class DownloadInfo < Container
      def initialize
        super(:downloading)
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
        {:path => @path, :bitmap => @bitmap, :chunk_size => @chunk_size, :fullsize => @fullsize}
      end
      def to_s
        # return progress status string
        "[ %2d%% ] #{@path}" % progress
      end
    end
  end
end
