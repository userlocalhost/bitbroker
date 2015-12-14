require 'spec_helper'

describe BitBroker::Manager do
  let(:shared_directory) { '' }
  before do
    @manager = BitBroker::Manager.new({
      :path => File.dirname(__FILE__),
      :name => 'spec-test',
      :mqconfig => MQCONFIG,
    })

    @manager.start_metadata_receiver
  end
  after do
    @manager.stop_metadata_receiver
  end

  context "receive advertisement" do
    it "need all files"
    it "need part of files"
    it "need no file"
  end

  context "receive request_all" do
    it "has all files"
    it "has part of files"
    it "has no file"
  end

  context "receive suggestion" do
    it "has target file"
    it "doesn't have"
  end

  context "receive request" do
    it "has target file"
    it "doesn't have"
  end
end
