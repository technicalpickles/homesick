# frozen_string_literal: true

require 'spec_helper'

class DummyHomesick
  include Homesick::Utils

  def public_repos_dir = repos_dir
end

describe Homesick::Utils do
  around do |example|
    original_envs = ENV.slice('HOME', 'HOMESICKDIR')
    ENV.merge!({ 'HOME' => home.to_s, 'HOMESICKDIR' => homesickdir })

    example.run

    ENV.merge!(original_envs)
    home.destroy!
  end

  let(:home) { create_construct }
  let(:homesick) { DummyHomesick.new }
  let(:homesickdir) { nil }

  context 'when HOMESICKDIR not set' do
    describe '#repos_dir' do
      it 'defaults to ~/.homesick' do
        expect(homesick.public_repos_dir).to eq(Pathname("#{home}/.homesick/repos"))
      end
    end
  end

  context 'when custom HOMESICKDIR is set' do
    let(:homesickdir) { '/custom-dir' }

    describe '#repos_dir' do
      it 'uses HOMESICKDIR' do
        expect(homesick.public_repos_dir).to eq(Pathname('/custom-dir/repos'))
      end
    end
  end
end
