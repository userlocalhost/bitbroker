module BitBroker
  class ProgressManager
    STATUS_DOWNLOADING = 1 << 0
    STATUS_UPLOADING = 1 << 1

    # initialize class instance variables
    @downloadings = @uploadings = []

    def self.downloading(opts)
      progress = @downloadings.find {|x| x.path == opts[:path]}
      if progress == nil
        opts[:status] = STATUS_DOWNLOADING
        progress = Progress.new(opts)

        # append class variables
        @downloadings.push progress
      end

      progress.update(opts[:offset])
    end
    def self.show_downloadings
      @downloadings.each do |progress|
        puts progress.get_status
      end
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
