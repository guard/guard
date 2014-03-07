require 'spec_helper'

describe Guard::Sheller, :sheller_specs do
  let(:sheller) { described_class.new('pwd') }
  let(:fake_sheller) { o = double; o.stub(run: true, stdout: ''); o }
  let(:pwd_stdout) { `pwd` }

  describe '.run' do
    it 'instantiate a new Sheller object' do
      expect(described_class).to receive(:new).with('pwd').and_return(fake_sheller)

      described_class.run('pwd')
    end

    it 'calls #run on the new Sheller object' do
      expect(described_class).to receive(:new).and_return(fake_sheller)
      expect(fake_sheller).to receive(:run)

      described_class.run('pwd')
    end
  end

  describe '.stdout' do
    it 'instantiate a new Sheller object' do
      expect(described_class).to receive(:new).with('pwd').and_return(fake_sheller)

      described_class.stdout('pwd')
    end

    it 'calls #run on the new Sheller object' do
      expect(described_class).to receive(:new).and_return(fake_sheller)
      expect(fake_sheller).to receive(:stdout)

      described_class.stdout('pwd')
    end
  end

  describe '#new' do
    it 'accepts a string arg' do
      sheller = described_class.new('pwd')
      expect(sheller).to receive(:`).with 'pwd'

      sheller.run
    end

    it 'accepts a list of string args' do
      sheller = described_class.new('ls', '-l')
      expect(sheller).to receive(:`).with 'ls -l'

      sheller.run
    end

    it 'accepts an array of string args' do
      sheller = described_class.new(['ls', '-l'])
      expect(sheller).to receive(:`).with 'ls -l'

      sheller.run
    end
  end

  describe '#run' do
    it 'runs the given command using `' do
      expect(sheller).to receive(:`).with 'pwd'

      sheller.run
    end

    it 'exposes the command status' do
      sheller.run

      expect(sheller.status).to be_a(Process::Status)
    end
  end

  describe '#stdout' do
    it 'returns the command output' do
      sheller.run

      expect(sheller.stdout).to eq pwd_stdout
    end

    it 'runs the command if not run yet and returns its output' do
      expect(sheller.stdout).to eq pwd_stdout
    end
  end

  describe '#success?' do
    it 'returns the command success' do
      sheller.run

      expect(sheller).to be_success
    end
  end

end
