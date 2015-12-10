require 'bunny'
require 'msgpack'

module BitBroker
  # This method communicate with AMQP for transmitting and receiving data
  class Broker
    def initialize(name)
      config = Manager.mqconfig

      @connection = Bunny.new(:host     => config['host'],
                              :vhost    => config['vhost'],
                              :user     => config['user'],
                              :password => config['passwd'])
      @connection.start
      @channel = @connection.create_channel
      @exchange = @channel.direct(name)
    end

    def finish
      @channel.close
      @connection.close
    end
  end

  class Publisher < Broker
    def initialize(name)
      super(name)
    end
    def send(rkey, data)
      @exchange.publish(MessagePack.pack(data), :routing_key => rkey)
      finish
    end
  end

  class Subscriber < Broker
    SIGNAL_TERM = 'TERM'
    def initialize(name)
      super(name)
    end

    def receive(rkey, &block)
      queue = @channel.queue('', :exclusive => true)
      queue.bind(@exchange, :routing_key => rkey)
      begin
        queue.subscribe(:block => true) do |info, prop, binary|
          block.call(MessagePack.unpack(binary))
        end
      rescue Exception => _
        finish
      end
    end
  end
end
