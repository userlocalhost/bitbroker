require 'msgpack'
require 'fileutils'

module BitBroker
  class Solvant
    DEFAULT_CHUNK_SIZE = 1<<20

    attr_reader :chunks

    def initialize(dirpath, r_path, chunk_size = DEFAULT_CHUNK_SIZE)
      @f_path = "#{dirpath}/#{r_path}"

      # Validate target file at first
      if not FileTest.exist? @f_path
        FileUtils.touch(@f_path)
      end

      # separate per chunk
      @chunks = []
      chunk_splitter(File::Stat.new(@f_path).size, chunk_size) do |offset, size|
        @chunks.push(Chunk.new({
          :r_path => r_path,
          :f_path => @f_path,
          :size => size,
          :offset => offset,
          :chunk_size => chunk_size,
        }))
      end
    end

    class Chunk
      def initialize(opts)
        @r_path = opts[:r_path]
        @f_path = opts[:f_path]
        @size = opts[:size]
        @offset = opts[:offset]
        @chunk_size = opts[:chunk_size]
      end

      def serialize
        MessagePack.pack({
          'path' => @r_path,
          'data' => File.binread(@f_path, @size, @offset * @chunk_size),
          'offset' => @offset,
          'chunk_size' => @chunk_size,
        })
      end
    end

    # This defines operations to manipulate actual Flie object on FileSystem
    def remove
      File.unlink(@f_path)
    end

    def upload broker
      @chunks.each do |chunk|
        broker.send_data(chunk.serialize)
      end
    end

    def upload_to(broker, dest)
      @chunks.each do |chunk|
        broker.send_p_data(dest, chunk.serialize)
      end
    end

    def self.load_binary(dirpath, binary)
      data = MessagePack.unpack(binary)
      offset = data['offset'] * data['chunk_size']

      File.binwrite(dirpath + data['path'], data['data'], offset)
    end
  
    private
    def chunk_splitter(total_size, chunk_size, &block)
      last = total_size / chunk_size
      (0..last).each do |i|
        size = (i == last) ? total_size - chunk_size * i : chunk_size

        block.call(i, size)
      end
    end
  end
end
