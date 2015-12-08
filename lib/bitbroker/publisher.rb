module BitBroker
  class Publisher < Broker
    def initialize
      super
    end
    def send(name, rkey, data)
      @channel.direct(name).publish(data, :ruoting_key => rkey)
    end
  end
end
