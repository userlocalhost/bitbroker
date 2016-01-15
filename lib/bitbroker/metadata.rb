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
        Log.warn("Warning: #{path} is already created")
      end
    end

    ### sending message for broker
    def advertise(broker)
      broker.send_metadata({
        :type => TYPE_ADVERTISE,
        :data => @files.map{|x| x.to_h },
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
      attr_reader :path, :size, :mtime

      def initialize(dirpath, filepath)
        @fpath = "#{dirpath}/#{filepath}"
        @path = filepath

        self.update
      end
      def update
        if FileTest.exist? @fpath
          file = File.new(@fpath)

          @size = file.size
          @mtime = file.mtime
        else
          @size = 0
          @mtime = Time.new(0)
        end
      end
      def to_h
        {
          'path' => @path,
          'size' => @size,
          'mtime' => @mtime.to_s,
        }
      end
    end
  end
end
