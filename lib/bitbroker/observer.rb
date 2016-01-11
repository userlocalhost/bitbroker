require 'listen'

module BitBroker
  class Observer
    def initialize(dir, &block)
      @target_dir = dir

      @listener = Listen.to(dir) do |mod, add, _rem|
        block.call(mod, add)
      end

      @listener.start
    end

    def stop
      @listener.stop
    end
  end
end
