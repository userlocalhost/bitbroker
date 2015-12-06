require 'msgpack'
require 'fileutils'

module BitBroker
  class Solvant
    DEFAULT_CHUNK_SIZE = 1<<20

    attr_reader :chunks

    def initialize(path, chunk_size = DEFAULT_CHUNK_SIZE)
      # Validate target file at first
      if not FileTest.exist? path
        FileUtils.touch(path)
      end

      # initialize parameters
      @info = File.new(path)
      @chunks = []

      # separate per chunk
      chunk_splitter(@info.stat.size, chunk_size) do |offset, size|
        #@chunks.push(Chunk.new(path, offset, size))
        @chunks.push(Chunk.new({
          :path => path,
          :size => size,
          :offset => offset,
          :chunk_size => chunk_size,
        }))
      end
    end

    class Chunk
      def initialize(opts)
        @path = opts[:path]
        @size = opts[:size]
        @offset = opts[:offset]
        @chunk_size = opts[:chunk_size]
      end

      def serialize
        MessagePack.pack({
          'path' => @path,
          'data' => File.binread(@path, @size, @offset * @chunk_size),
          'offset' => @offset,
          'chunk_size' => @chunk_size,
        })
      end
    end

    # This defines operations to manipulate actual Flie object on FileSystem
    def remove
      File.unlink(@info.path)
    end

    def upload
      broker = Broker.new

      @chunks.each do |chunk|
        broker.send(chunk.serialize)
      end
    end

    def load_binary binary
      data = MessagePack.unpack(binary)
      offset = data['offset'] * data['chunk_size']

      File.binwrite(@info.path, data['data'], offset)
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
