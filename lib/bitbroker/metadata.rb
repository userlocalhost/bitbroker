module BitBroker
  class Metadata
    def initialize path
      @files = scanning_files(path).map do
        FileInfo.new path
      end
    end
    def adv
      ### no implementation
    end
    def req
      ### no implementation
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
      attr_reader :path, :timestamp
      def initialize path
        @path = path
        @timestamp = File.mtime(path)
      end
    end
  end
end
