require 'msgpack'

module BitBroker
  class Publisher < Broker
    def initialize
      super
    end
    def send(rkey, data)
      @exchange.publish(MessagePack.pack(data), :ruoting_key => rkey)
    end
  end
end
