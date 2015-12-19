require 'yaml'

module BitBroker
  class Config
    DEFAULT_CONFIG_PATH = "#{ENV['HOME']}/.bitbroker/config.yml"

    def self.[](param)
      YAML.load_file(config_path)[param]
    end

    def self.config_path
      @config_path ||= DEFAULT_CONFIG_PATH
    end

    def self.set_config(path)
      unless FileTest.exist? path
        raise InvalidFile path
      end
      @config_path = path
    end
  end
end
