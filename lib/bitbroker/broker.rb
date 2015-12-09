module BitBroker
  # This method communicate with AMQP for transmitting and receiving data
  class Broker
    def initialize
      config = Manager.mqconfig

      @connection = Bunny.new(:host   => config[:host],
                              :vhost  => config[:vhost],
                              :user   => config[:user],
                              :passwd => config[:passwd])
      @connection.start
      @channel = @connection.create_channel
      @exchange = @channel.direct(config['name'])
    end

    def stop
      @channel.stop
      @connection.stop
    end
  end
end
