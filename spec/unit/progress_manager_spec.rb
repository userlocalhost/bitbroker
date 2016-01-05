require 'spec_helper'

describe BitBroker::ProgressManager do
  context "test download progress processing" do
    before do
      BitBroker::ProgressManager.downloading({
        :path => 'dummy_path',
        :fullsize => 1000,
        :chunk_size => 10,
        :offset => 3,
      })

      @arr = BitBroker::ProgressManager.instance_variable_get(:@downloadings)
    end

    it "create progress object in downloadings array" do
      expect(@arr.size).to be > 0
    end
    it "initialize progress object safety" do
      expect(@arr.first.bitmap.size).to eq 100
    end
    it "could get correct progress percentage" do
      expect(@arr.first.progress).to eq '01'
    end
  end
end
