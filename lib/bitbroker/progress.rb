require 'msgpack'

module BitBroker
  class ProgressManager
    def self.uploading(opts)
      container = Container.new
      self.update_progress(opts, container.uploading)
      container.save
    end
    def self.downloading(opts)
      container = Container.new
      self.update_progress(opts, container.downloading)
      container.save
    end

    def self.now_downloadings
      container = Container.new
      container.downloading.map { |x| x.get_status if x.progress < 100 }
    end
    def self.now_uploadings
      container = Container.new
      container.uploading.map { |x| x.get_status if x.progress < 100 }
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
      PATH_UPLOADING = "#{ENV['HOME']}/.bitbroker/.uploadings"
      PATH_DOWNLOADING = "#{ENV['HOME']}/.bitbroker/.downloadings"

      attr_reader :uploading, :downloading
      def initialize
        def fileload(path, &block)
          if FileTest.exist? path
            MessagePack.unpack(File.read(path)).each do |data|
              block.call(BitBroker::ProgressManager::Progress.new({
                :path => data['path'],
                :bitmap => data['bitmap'],
                :fullsize => data['fullsize'],
                :chunk_size => data['chunk_size'],
              }))
            end
          end
        end

        @uploading = @downloading = []
        fileload(PATH_UPLOADING) {|obj| @uploading.push(obj)}
        fileload(PATH_DOWNLOADING) {|obj| @downloading.push(obj)}
      end
      def save
        File.write(PATH_UPLOADING, MessagePack.pack(@uploading.map{|x| x.serialize}))
        File.write(PATH_DOWNLOADING, MessagePack.pack(@downloading.map{|x| x.serialize}))
      end
    end

    # This describes 
    class Progress
      attr_reader :path

      def initialize(opts)
        length = opts[:fullsize] / opts[:chunk_size]
        length += 1 if opts[:fullsize] % opts[:chunk_size] > 0

        @chunk_size = opts[:chunk_size]
        @fullsize = opts[:fullsize]
        @path = opts[:path]

        @bitmap = opts[:bitmap]
        @bitmap = Array.new(length, false) unless !!@bitmap
      end
      def update(index)
        @bitmap[index] = true
      end
      def get_status
        # return progress status
        "[ %2d%% ] #{@path}" % progress
      end
      def progress
        # return progress percentage
        100 * @bitmap.select{|x| x}.size / @bitmap.size
      end
      def serialize
        {'path' => @path, 'bitmap' => @bitmap, 'chunk_size' => @chunk_size, 'fullsize' => @fullsize}
      end
    end
  end
end
