require 'spec_helper'

describe BitBroker::Solvant do
  let(:temporary_path) { SecureRandom.uuid + 'bitbroker-test' }

  def data_generate size
    (1..size).map{'.'}.join
  end

  context "with existed file" do
    it 'specifies a small file' do
      solvant = BitBroker::Solvant.new(__FILE__)
      expect(solvant.chunks.count).to eq(1)
    end
    it 'specifies a big file' do
      File.write(temporary_path, data_generate(1<<21))
      solvant = BitBroker::Solvant.new(temporary_path)

      expect(solvant.chunks.count).to be > 1

      File.unlink(temporary_path)
    end
  end

  context "with new file" do
    before do
      @solvant = BitBroker::Solvant.new(temporary_path)
    end
    after do
      File.unlink(temporary_path) if FileTest.exist? temporary_path
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
                     data['offset'] * data['chunk_size'])).to eq(data['data'])
    end
    it "remove file" do
      @solvant.remove

      expect(File).not_to exist(temporary_path)
    end
  end
end
