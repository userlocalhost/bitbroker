require 'spec_helper'

describe BitBroker::Manager do
  DIRPATH = File.dirname(__FILE__) + '/.test/manager'

  def mkdir
    FileUtils.mkdir_p(DIRPATH) if not FileTest.exist? DIRPATH

    # preparing existed files
    ['foo', 'bar'].each do |path|
      FileUtils.touch("#{DIRPATH}/#{path}")
    end
  end
  def rmdir
    Dir.foreach(DIRPATH) do |file|
      File::delete("#{DIRPATH}/#{file}") if /^\.+$/ !~ file
    end
    Dir.rmdir(DIRPATH)
  end

  before(:all) do
    mkdir
    @manager = BitBroker::Manager.new({
      :path => DIRPATH,
      :name => 'spec-test',
      :mqconfig => MQCONFIG,
    })

    @manager.start_receiver
  end
  after(:all) do
    @manager.stop_receiver
    rmdir
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
