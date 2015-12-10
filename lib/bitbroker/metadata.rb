require 'msgpack'

module BitBroker
  class Metadata
    TYPE_ADVERTISE = 1<<0
    TYPE_REQUEST_ALL = 1<<1
    TYPE_SUGGESTION = 1<<2
    TYPE_REQUEST = 1<<3

    def initialize(dir, config)
      @config = config
      @broker = Publisher.new(@config)
      @files = scanning_files(dir).map do |path|
        FileInfo.new(dir, path)
      end
    end
    def advertise
      @broker.send_metadata({
        :type => TYPE_ADVERTISE,
        :data => @files.map{|x| x.serialize },
      })
    end
    def request_all(files)
      @broker.send_metadata({
        :type => TYPE_REQUEST_ALL,
        :data => files,
      })
    end
    def suggestion(files, dest)
      @broker.send_p_metadata(dest, {
        :type => TYPE_SUGGETSION,
        :data => files,
      })
    end
    def request(files, dest)
      @broker.send_p_metadata(dest, {
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
      def initialize(dir, path)
        @dir = dir
        @path = path
      end
      def serialize
        file = File.new(@path)
        {
          'path'  => get_relative_path(@dir, @path),
          'size'  => file.size,
          'mtime' => file.mtime.to_s,
        }
      end

      private
      def get_relative_path(dir, path)
        raise DiscomfortDirectoryStructure unless !!path.match(/^#{dir}/)
        path.split(dir).last
      end
    end
  end
end
