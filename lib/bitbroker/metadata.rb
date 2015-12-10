require 'msgpack'

module BitBroker
  class Metadata
    ROUTING_KEY = 'metadata'

    TYPE_ADVERTISE = 1<<0
    TYPE_REQUEST_ALL = 1<<1
    TYPE_SUGGESTION = 1<<2
    TYPE_REQUEST = 1<<3

    def initialize(dirpath, name)
      @namelabel = name
      @files = scanning_files(dirpath).map do |path|
        FileInfo.new(path)
      end
    end
    def advertise
      send({
        :type => TYPE_ADVERTISE,
        :routing_key => ROUTING_KEY,
        :data => @files.map{|x| x.serialize },
      })
    end
    def request_all(files)
      send({
        :type => TYPE_REQUEST_ALL,
        :routing_key => ROUTING_KEY,
        :data => files,
      })
    end
    def suggestion(files, rkey)
      send({
        :type => TYPE_SUGGETSION,
        :routing_key => rkey,
        :data => files,
      })
    end
    def request(files, rkey)
      send({
        :type => TYPE_REQUEST,
        :routing_key => rkey,
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
    def send opts
      mqconfig = Manager.mqconfig
      broker = Publisher.new(@namelabel)

      broker.send(opts[:routing_key], {
        'type' => opts[:type],
        'data' => opts[:data],
        'routing_key' => mqconfig[:prkey_metadata],
      })
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
          'mtime' => @mtime.to_s,
        }
      end
    end
  end
end
