#!/usr/bin/env ruby

require 'msgpack'
require 'fileutils'

module BitBroker
  class Solvant
    DEFAULT_CHUNK_SIZE = 1<<20

    def initialize(path, chunk_size = DEFAULT_CHUNKSIZE)
      @info = File.new(path)
      @chunks = []

      # the case target file isn't exist
      begin
      rescue Errno::ENOENT => e
        
      end

      # separate per chunk
      chunk_splitter(@info.stat.size, chunk_size) do |offset, size|
        @chunks.push(Chunk.new(path, offset, size))
      end
    end

    class Chunk
      def initialize(path, offset, size)
        @path = path
        @size = size
        @offset = offset
      end

      def to_h
        {
          'data': IO.binread(@path, @size, @offset),
          'offset': @offset,
        }
      end
    end

    # This defines operations to manipulate actual Flie object on FileSystem
    def upload(publisher)
      publisher.send(self.serialize)
    end
  
    def remove
      File.delete(opts[:path])
    end
  
    def save opts
      File.binwrite(opts[:path], opts[:data])
      @status.set 
    end

    def upload broker
      @chunks.each do |chunk|
        binary = MessagePack.pack(chunk.to_h.merge({
          'path' => @info.path,
          'total' => @chunks.length
        }))

        broker.send(binary)
      end
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
