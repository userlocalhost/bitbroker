require 'listen'

module BitBroker
  class Observer
    def initialize dir
      @target_dir = dir
      @listener = Listen.to(dir) do |mod, add, rem|
        handle_mod(mod) if mod != []
        handle_add(add) if add != []
        handle_rem(rem) if rem != []
      end

      @listener.start
    end

    def stop
      @listener.stop
    end

    private
    def handle_add file
      Solvant.new(file).upload
    end

    def handle_mod file
      Solvant.new(file).upload
    end

    def handle_rem file
      Solvant.new(file).remove
    end
  end
end
