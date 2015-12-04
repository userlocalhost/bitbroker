require 'spec_helper'

describe BitBroker::Solvant do
  let(:temporary_path) { SecureRandom.uuid + 'bitbroker-test' }

  context "with existed file" do
    it 'specifies a small file'
    it 'specifies a big file'
  end

  context "with new file" do
    before do
      @solvant = BitBroker::Solvant.new(temporary_path)
    end
    after do
      File.unlink(temporary_path)
    end
    it 'create a new solvant' do
      expect(File).to exist(temporary_path)
    end
    it 'load from broker' do
      bin = ['dummy']
      data = {
        'data' => 'dummy',
        'offset' => 8,
        'chunk_size' => 24,
      }
      allow(MessagePack).to receive(:unpack).with(bin).and_return(data)

      @solvant.load_binary bin

      expect(IO.read(temporary_path, 
                     data['data'].length,
                     data['offset'] * data['chunk_size'])).to eql(data['data'])
    end
  end
end
