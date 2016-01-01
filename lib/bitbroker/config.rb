require 'yaml'

module BitBroker
  class Config
    DEFAULT_PATH_CONFIG = "#{ENV['HOME']}/.bitbroker/config"
    DEFAULT_PATH_PID = "#{ENV['HOME']}/.bitbroker/pid"

    def self.[](param)
      YAML.load_file(path_config)[param]
    end

    def self.path_config
      @path_config ||= DEFAULT_PATH_CONFIG
    end
    def self.path_pid
      @path_pid ||= DEFAULT_PATH_PID
    end

    def self.set_config(path)
      unless FileTest.exist? path
        raise InvalidFile path
      end
      @path_config = path
    end
  end
end
