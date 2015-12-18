require 'msgpack'

module BitBroker
  class Metadata
    # describes message types
    TYPE_ADVERTISE = 1<<0
    TYPE_REQUEST_ALL = 1<<1
    TYPE_SUGGESTION = 1<<2
    TYPE_REQUEST = 1<<3

    attr_reader :dir

    def initialize(dir)
      @dir = dir
      @files = scanning_files(@dir).map do |path|
        FileInfo.new(@dir, get_rpath(path))
      end
    end

    def get_with_path(path)
      @files.select{|f| f.path == path}.first
    end
    def remove_with_path(path)
      @files.reject!{|f| f.path == path}
    end
    def create(path)
      if get_with_path(path) == nil
        @files.push(FileInfo.new(@dir, path))
      else
        puts "Warning: #{path} is already created"
      end
    end

    ### sending message for broker
    def advertise(broker)
      broker.send_metadata({
        :type => TYPE_ADVERTISE,
        :data => @files.map{|x| x.serialize },
      })
    end
    def request_all(broker, files)
      broker.send_metadata({
        :type => TYPE_REQUEST_ALL,
        :data => files,
      })
    end
    def suggestion(broker, files, dest)
      broker.send_p_metadata(dest, {
        :type => TYPE_SUGGESTION,
        :data => files,
      })
    end
    def request(broker, files, dest)
      broker.send_p_metadata(dest, {
        :type => TYPE_REQUEST,
        :data => files,
      })
    end

    ### utility methods
    def get_rpath(path)
      raise DiscomfortDirectoryStructure unless !!path.match(/^#{@dir}/)
      path.split(@dir).last
    end

    private
    def scanning_files(current_dir, &block)
      arr = []
      Dir.foreach(current_dir) do |f|
        if /^\.+$/ !~ f
          path = "#{current_dir}/#{f}"

          if File.directory? f
            arr += scanning(path)
          else
            arr.push(path)
          end
        end
      end
      arr
    end
    class FileInfo
      attr_reader :path

      # describes file status
      STATUS_REMOVED = 1 << 0

      def initialize(dirpath, filepath)
        @fpath = "#{dirpath}/#{filepath}"
        @path = filepath
        @status = 0
      end
      def removed?
        @status & STATUS_REMOVED > 0
      end
      def remove
        @status |= STATUS_REMOVED
      end
      def info
        File.new(@fpath)
      end
      def serialize
        file = File.new(@fpath)
        {
          'path'  => @path,
          'size'  => file.size,
          'mtime' => file.mtime.to_s,
          'status' => @status,
        }
      end
    end
  end
end
