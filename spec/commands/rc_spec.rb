require 'spec_helper'

describe 'rc' do
  let(:home) { create_construct }
  after { home.destroy! }

  let(:castles) { home.directory('.homesick/repos') }

  let(:homesick) { Homesick::Commands::Rc.new }

  before { homesick.stub(:repos_dir).and_return(castles) }

  let(:castle) { given_castle('glencairn') }

  context 'when told to do so' do
    before do
      expect($stdout).to receive(:print)
      expect($stdin).to receive(:gets).and_return('y')
    end

    it 'executes the .homesickrc' do
      castle.file('.homesickrc') do |file|
        file << "File.open(Dir.pwd + '/testing', 'w') { |f| f.print 'testing' }"
      end

      homesick.rc castle

      castle.join('testing').should exist
    end
  end

  context 'when told not to do so' do
    before do
      expect($stdout).to receive(:print)
      expect($stdin).to receive(:gets).and_return('n')
    end

    it 'does not execute the .homesickrc' do
      castle.file('.homesickrc') do |file|
        file << "File.open(Dir.pwd + '/testing', 'w') { |f| f.print 'testing' }"
      end

      homesick.rc castle

      castle.join('testing').should_not exist
    end
  end
end

