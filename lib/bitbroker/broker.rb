require 'bunny'

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
end
