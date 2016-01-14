require 'msgpack'
require 'fileutils'

module BitBroker
  class Solvant
    DEFAULT_CHUNK_SIZE = 1<<20

    attr_reader :chunks

    def initialize(dirpath, r_path, chunk_size = DEFAULT_CHUNK_SIZE)
      @f_path = "#{dirpath}#{r_path}"

      # Validate target file at first
      if not FileTest.exist? @f_path
        FileUtils.touch(@f_path)
      end

      # separate per chunk
      @chunks = Array.new
      chunk_splitter(File::Stat.new(@f_path).size, chunk_size) do |offset, size|
        obj = Chunk.new({
          :r_path => r_path,
          :f_path => @f_path,
          :size => size,
          :offset => offset,
          :chunk_size => chunk_size,
        })

        @chunks.push(obj)
      end
    end

    def upload broker
      @chunks.each do |chunk|
        # update progress infomation
        ProgressManager.uploading({
          :path => @f_path,
          :fullsize => chunk.fullsize,
          :chunk_size => chunk.chunk_size,
          :offset => chunk.offset,
        })

        broker.send_data(chunk.serialize)
      end
    end

    def upload_to(broker, dest)
      @chunks.each do |chunk|
        # update progress infomation
        ProgressManager.uploading({
          :path => @f_path,
          :fullsize => chunk.fullsize,
          :chunk_size => chunk.chunk_size,
          :offset => chunk.offset,
        })

        broker.send_p_data(dest, chunk.serialize)
      end
    end

    def self.load_binary(dirpath, binary)
      data = MessagePack.unpack(binary)
      offset = data['offset'] * data['chunk_size']

      # update progress infomation
      ProgressManager.downloading({
        :path => @f_path,
        :fullsize => data['fullsize'],
        :chunk_size => data['chunk_size'],
        :offset => data['offset'],
      })

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

    class Chunk
      attr_reader :chunk_size, :offset, :fullsize

      def initialize(opts)
        @r_path = opts[:r_path]
        @f_path = opts[:f_path]
        @size = opts[:size]
        @offset = opts[:offset]
        @chunk_size = opts[:chunk_size]
        @fullsize = File.size(@f_path)
      end

      def serialize
        MessagePack.pack({
          'path' => @r_path,
          'data' => File.binread(@f_path, @size, @offset * @chunk_size),
          'offset' => @offset,
          'chunk_size' => @chunk_size,
          'fullsize' => @fullsize,
        })
      end
    end
  end
end
