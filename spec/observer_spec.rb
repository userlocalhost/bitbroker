require 'spec_helper'

describe BitBroker::Observer do

  def rmdir_all(dirpath)
    Dir.foreach(dirpath) do |file|
      File::delete("#{dirpath}/#{file}") if /^\.+$/ !~ file
    end
    Dir.rmdir(dirpath)
  end

  context "file operations" do
    let(:temporary_path) { 'spec/.test/observer_test' }

    before do
      dirpath = File.dirname(temporary_path)
      Dir.mkdir(dirpath) if not FileTest.exist? dirpath

      @observer = BitBroker::Observer.new(dirpath)
    end

    after do
      @observer.stop
      rmdir_all(File.dirname(temporary_path))
    end

    it "create a new file" do
      handler_is_called = false
      allow_any_instance_of(BitBroker::Observer).to receive(:handle_add) { handler_is_called = true }

      # create a new file and wait until the handler of Observer is called
      FileUtils.touch(temporary_path)
      sleep 0.5

      expect(handler_is_called).to be true
    end
    it "modify a file" do
      handler_is_called = false
      allow_any_instance_of(BitBroker::Observer).to receive(:handle_add).and_return(true)
      allow_any_instance_of(BitBroker::Observer).to receive(:handle_mod) { handler_is_called = true }

      # create and modify a file, then wait for handler is called
      FileUtils.touch(temporary_path)
      sleep 0.8

      File.open(temporary_path, 'w') { |f| f.write('abcd') }
      sleep 0.5
      
      expect(handler_is_called).to be true
    end
    it "delete a file" do
      handler_is_called = false
      allow_any_instance_of(BitBroker::Observer).to receive(:handle_add).and_return(true)
      allow_any_instance_of(BitBroker::Observer).to receive(:handle_rem) { handler_is_called = true }

      # create and remove a file, then wait for handler is called
      FileUtils.touch(temporary_path)
      sleep 0.5

      File.unlink(temporary_path)
      sleep 0.5
      
      expect(handler_is_called).to be true
    end
  end
end
