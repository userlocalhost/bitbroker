require 'bunny'
require 'msgpack'

module BitBroker
  # This method communicate with AMQP for transmitting and receiving data
  class Broker
    RKEY_DATA = 'data'
    RKEY_METADATA = 'metadata'

    def initialize(config)
      @connection = Bunny.new(:host     => config[:mqconfig]['host'],
                              :vhost    => config[:mqconfig]['vhost'],
                              :user     => config[:mqconfig]['user'],
                              :password => config[:mqconfig]['passwd'])
      @connection.start
      @channel = @connection.create_channel
      @exchange = @channel.direct(config[:label])
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
      @exchange.publish(MessagePack.pack({
        'data' => data,
        'from' => Mac.addr,
      }), :routing_key => rkey)
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
      queue = @channel.queue('', :exclusive => true)
      queue.bind(@exchange, :routing_key => rkey)
      begin
        queue.subscribe(:block => true) do |info, prop, binary|
          msg = MessagePack.unpack(binary)

          if msg['from'] != Mac.addr
            block.call(msg['data'], msg['from'])
          end
        end
      rescue Exception => _
        finish
      end
    end
  end
end
