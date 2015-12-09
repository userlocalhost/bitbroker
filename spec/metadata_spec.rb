require 'spec_helper'

describe BitBroker::Metadata do
  let(:dirname) { File.dirname(__FILE__) }

  context 'metadata basic operation' do
    before do
      @metadata = BitBroker::Metadata.new(dirname)
    end
    it "safe to make a metadata object" do
      expect(@metadata.instance_variable_get(:@files).count).to be > 1
    end
    it "safe to advertise metadata" do
      # action
      @metadata.advertise
    end
    it "safe to request_all metadata" do
      # action
      files = Dir.glob("#{dirname}/*")

      @metadata.request_all(files)
    end
    it "safe to suggestion metadata" do
      r_key = 'testuser-metadata'
      files = [__FILE__]

      @metadata.suggestion(file, r_key)
    end
    it "safe to request metadata" do
      r_key = 'testuser-metadata'
      files = [__FILE__]

      @metadata.request(file, r_key)
    end
  end
end
