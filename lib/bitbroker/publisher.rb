require 'msgpack'

module BitBroker
  class Publisher < Broker
    def initialize(name)
      super(name)
    end
    def send(rkey, data)
      @exchange.publish(MessagePack.pack(data), :routing_key => rkey)
      finish
    end
  end
end
