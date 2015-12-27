require 'spec_helper'

describe BitBroker::Log do
  context "output log message" do
    LOGFILE = File.dirname(__FILE__) + "/.log"

    before do
      allow(BitBroker::Config).to receive(:[]).with('logfile').and_return(LOGFILE)
    end
    after(:all) do
      File.unlink(LOGFILE) if FileTest.exist? LOGFILE
    end

    it "with normal (info)" do
      BitBroker::Log.level = Logger::INFO
      BitBroker::Log.info("hoge")

      expect(IO.read(LOGFILE)).to match(/INFO.*hoge/)
    end
    it "with warning" do
      BitBroker::Log.level = Logger::WARN
      BitBroker::Log.warn("fuga")

      expect(IO.read(LOGFILE)).to match(/WARN.*fuga/)
    end
    it "with info, but log-level is warning" do
      BitBroker::Log.level = Logger::WARN
      BitBroker::Log.debug("puyo")

      expect(IO.read(LOGFILE)).not_to match(/DEBUG.*puyo/)
    end
  end
end
