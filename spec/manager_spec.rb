require 'spec_helper'

describe BitBroker::Manager do
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
