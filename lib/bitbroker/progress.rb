module BitBroker
  class ProgressManager
    TYPE_DOWNLOADING = 1 << 0
    TYPE_UPLOADING = 1 << 1

    # initialize class instance variables
    @downloadings = @uploadings = []

    def self.uploading(opts)
      self.update_progress(opts, TYPE_UPLOADING)
    end
    def self.downloading(opts)
      self.update_progress(opts, TYPE_DOWNLOADING)
    end

    def self.show_downloadings
      @downloadings.each do |progress|
        puts progress.get_status
      end
    end

    private
    def self.update_progress(opts, type)
      case type
      when TYPE_DOWNLOADING
        container_name = :@downloadings
      when TYPE_UPLOADING
        container_name = :@uploadings
      end
      container = self.instance_variable_get(container_name)

      progress = container.find {|x| x.path == opts[:path]}
      if progress == nil
        opts[:status] = type
        progress = Progress.new(opts)

        # append class variables
        self.instance_variable_set(container_name, @downloadings.push(progress))
      end

      progress.update(opts[:offset])
    end

    # This describes 
    class Progress
      attr_reader :path, :bitmap

      def initialize(opts)
        length = opts[:fullsize] / opts[:chunk_size]
        length += 1 if opts[:fullsize] % opts[:chunk_size] > 0

        @path = opts[:path]
        @status = opts[:status]
        @bitmap = Array.new(length, false)
      end
      def update(index)
        @bitmap[index] = true
      end
      def get_status
        # return progress status
        "[#{progress}] #{@path}"
      end
      def progress
        # return progress percentage
        "%02d" % (100 * @bitmap.select{|x| x}.size / @bitmap.size)
      end
    end
  end
end
