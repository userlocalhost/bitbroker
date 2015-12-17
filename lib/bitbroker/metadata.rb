require 'msgpack'

module BitBroker
  class Metadata
    TYPE_ADVERTISE = 1<<0
    TYPE_REQUEST_ALL = 1<<1
    TYPE_SUGGESTION = 1<<2
    TYPE_REQUEST = 1<<3

    def initialize(dir)
      @files = scanning_files(dir).map do |path|
        FileInfo.new(dir, path)
      end
    end
    def getfile_with_path(path)
      @files.select{|f| f.r_path == path}.first
    end

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

      def initialize(dir, path)
        @dir = dir
        @path = path
      end
      def r_path
        raise DiscomfortDirectoryStructure unless !!path.match(/^#{@dir}/)
        @path.split(@dir).last
      end
      def info
        File.new(@path)
      end
      def serialize
        file = File.new(@path)
        {
          'path'  => r_path,
          'size'  => file.size,
          'mtime' => file.mtime.to_s,
        }
      end
    end
  end
end
