require 'leveldb'
require 'msgpack'

module BitBroker
  class ProgressManager
    def self.uploading(opts = nil)
      container = UploadInfo.new
      if opts == nil
        container
      else
        self.update_progress(opts, container)
      end
    end
    def self.downloading(opts = nil)
      container = DownloadInfo.new
      if opts == nil
        container
      else
        self.update_progress(opts, container)
      end
    end

    private
    def self.update_progress(opts, container)
      # create progress object
      data = container[opts['path']]
      progress = data != nil ? Progress.new(data) : Progress.new(opts)

      # update progress bitmap
      progress.update(opts['offset'])

      # save progress infomation to the database
      container[opts['path']] = progress.serialize

      # close leveldb object
      container.close
    end
  end

  class Container
    def initialize(path)
      loop do
        begin
          @db = LevelDB::DB.new path
        rescue LevelDB::DB::Error => e
          Log.warn("[Container] (initialize) conflict is happend, retry it")
          sleep 0.5
          # retry it
        end
        break if !!@db
      end
    end
    def each(&block)
      @db.each do |_key, value|
        block.call(MessagePack.unpack(value))
      end
    end
    def [](path)
      if !!@db[path]
        MessagePack.unpack(@db[path])
      end
    end
    def []=(path, data)
      @db[path] = MessagePack.pack(data)
    end
    def close
      @db.close
    end
  end
  class UploadInfo < Container
    def initialize
      super Config::PATH_PROGRESS_UPLOAD
    end
  end
  class DownloadInfo < Container
    def initialize
      super Config::PATH_PROGRESS_DOWNLOAD
    end
  end

  # This describes 
  class Progress
    attr_reader :path, :last_update

    def initialize(opts)
      fullsize = opts['fullsize'].to_i
      chunk_size = opts['chunk_size'].to_i

      length = fullsize / chunk_size
      length += 1 if fullsize % chunk_size > 0

      @chunk_size = chunk_size
      @fullsize = fullsize
      @path = opts['path']
      @last_update = Time.now

      @bitmap = opts['bitmap']
      @bitmap = Array.new(length, false) unless !!@bitmap
    end
    def update(index)
      @bitmap[index] = true
      @last_update = Time.now
    end
    def rate
      # return progress percentage
      100 * @bitmap.select{|x| x}.size / @bitmap.size
    end
    def serialize
      {'path' => @path, 'bitmap' => @bitmap, 'chunk_size' => @chunk_size, 'fullsize' => @fullsize}
    end
    def to_s
      # return progress status string
      "[ %2d%% ] #{@path}" % rate
    end
  end
end
