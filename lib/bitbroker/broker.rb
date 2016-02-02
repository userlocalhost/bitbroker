require 'bunny'
require 'msgpack'
require 'openssl'

module BitBroker
  # This method communicate with AMQP for transmitting and receiving data
  class Broker
    RKEY_DATA = 'data'
    RKEY_METADATA = 'metadata'
    ENCRYPT_ALGORITHM = "AES-256-CBC"

    def initialize(config)
      @connection = Bunny.new(:host     => config[:mqconfig]['host'],
                              :vhost    => config[:mqconfig]['vhost'],
                              :user     => config[:mqconfig]['user'],
                              :password => config[:mqconfig]['passwd'])
      @connection.start
      @channel = @connection.create_channel
      @exchange = @channel.direct(config[:label])
      @passwd = config[:passwd].to_s + config[:label]
    end

    def finish
      @channel.close
      @connection.close
    end
  end

  class Publisher < Broker
    def initialize(config)
      super(config)
    end

    def send_data(data)
      send(RKEY_DATA, data)
    end
    def send_metadata(data)
      send(RKEY_METADATA, data)
    end
    def send_p_data(dest, data)
      send(RKEY_DATA + dest, data)
    end
    def send_p_metadata(dest, data)
      send(RKEY_METADATA + dest, data)
    end

    private
    def send(rkey, data)
      @exchange.publish(encode(MessagePack.pack({
        'data' => data,
        'from' => Mac.addr,
      })), :routing_key => rkey)
    end

    def encode(data)
      cipher = OpenSSL::Cipher::Cipher.new(ENCRYPT_ALGORITHM)
      cipher.encrypt
      cipher.pkcs5_keyivgen(@passwd)
      cipher.update(data) + cipher.final
    end
  end

  class Subscriber < Broker
    SIGNAL_TERM = 'TERM'

    def initialize(config)
      super(config)
    end

    def recv_data(&block)
      recv(RKEY_DATA, &block)
    end
    def recv_metadata(&block)
      recv(RKEY_METADATA, &block)
    end
    def recv_p_data(&block)
      recv(RKEY_DATA + Mac.addr, &block)
    end
    def recv_p_metadata(&block)
      recv(RKEY_METADATA + Mac.addr, &block)
    end

    private
    def recv(rkey, &block)
      queue = @channel.queue('', :exclusive => true, :arguments => {'x-queue-mode' => 'lazy'})
      queue.bind(@exchange, :routing_key => rkey)
      begin
        queue.subscribe(:block => true) do |info, prop, binary|
          msg = MessagePack.unpack(decode(binary))

          if msg['from'] != Mac.addr
            block.call(msg['data'], msg['from'])
          end
        end
      rescue OpenSSL::Cipher::CipherError => e
        Log.warn("[Subscriber] #{e.to_s}")
      rescue Exception => e
        Log.error e.to_s
        finish

        raise e
      end
    end
    def decode(encrypted_data)
      cipher = OpenSSL::Cipher::Cipher.new(ENCRYPT_ALGORITHM)
      cipher.decrypt
      cipher.pkcs5_keyivgen(@passwd)
      cipher.update(encrypted_data) + cipher.final
    end
  end
end
