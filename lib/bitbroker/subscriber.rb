module BitBroker
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
