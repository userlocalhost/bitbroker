require 'listen'

module BitBroker
  class Observer
    def initialize(dir, &block)
      @target_dir = dir

      @listener = Listen.to(dir) do |mod, add, rem|
        block.call(mod, add, rem)
      end

      @listener.start
    end

    def stop
      @listener.stop
    end
  end
end
