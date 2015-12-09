require 'msgpack'

module BitBroker
  class Metadata
    ROUTING_KEY = 'metadata'

    TYPE_ADVERTISE = 1<<0
    TYPE_REQUEST_ALL = 1<<1
    TYPE_SUGGESTION = 1<<2
    TYPE_REQUEST = 1<<3

    def initialize path
      @files = scanning_files(path).map do
        FileInfo.new(path)
      end
    end
    def advertise
      ### no implementation
    end
    def request_all(files)
      ### no implementation
    end
    def suggestion(files, rkey)
      ### no implementation
    end
    def request(files, rkey)
      ### no implementation
    end

    private
    def send(rkey, data)
      broker = Publisher.new
      broker.send(rkey, data)
    end

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
      def initialize(path)
        @path = path
        @size = File.size(path)
        @mtime = File.mtime(path)
      end
      def serialize
        {
          'path'  => @path,
          'size'  => @size,
          'mtime' => @mtime,
        }
      end
    end
  end
end
