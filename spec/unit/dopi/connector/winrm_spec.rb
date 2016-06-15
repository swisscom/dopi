require 'spec_helper'

class WinrmTestKlass
  include Dopi::Connector::Winrm
  attr_accessor :hash
end

describe Dopi::Connector::Winrm do
  before :each do
    @winrm = WinrmTestKlass.new
  end

  describe '#port' do
    it 'should return the default port if not specified' do
      expect(@winrm.port).to eq(5985)
    end
    it 'should return the port if it is specified' do
      @winrm.hash = {:port => 42}
      expect(@winrm.port).to eq(42)
    end
    it 'will raise and error if the port is not specified as a number' do
      @winrm.hash = {:port => '42'}
      expect{@winrm.port}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if the port is smaller than 1' do
      @winrm.hash = {:port => 0}
      expect{@winrm.port}.to raise_error Dopi::CommandParsingError
    end
    it 'will raise and error if the port is bigger than 65535' do
      @winrm.hash = {:port => 10000000}
      expect{@winrm.port}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#ssl' do
    it 'should return false if specified as false' do
      @winrm.hash = {:ssl => false}
      expect(@winrm.ssl).to be false
    end
    it 'should return true if not specified' do
      expect(@winrm.ssl).to be true
    end
    it 'will raise and error if specified wrong' do
      @winrm.hash = {:ssl => 'foo'}
      expect{@winrm.ssl}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#ca_trust_path' do
    it 'should return the path if specified' do
      @winrm.hash = {:ca_trust_path => 'spec/unit'}
      expect(@winrm.ca_trust_path).to eq('spec/unit')
    end
    it 'should return nil if not specified' do
      @winrm.hash = {:plugin => 'winrm'}
      expect(@winrm.ca_trust_path).to be nil
    end
    it 'will raise and error if specified wrong' do
      @winrm.hash = {:ca_trust_path => 'foo'}
      expect{@winrm.ca_trust_path}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#disable_sspi' do
    it 'should return false if specified as false' do
      @winrm.hash = {:disable_sspi => true}
      expect(@winrm.disable_sspi).to be true
    end
    it 'should return true if not specified' do
      expect(@winrm.disable_sspi).to be nil
    end
    it 'will raise and error if specified wrong' do
      @winrm.hash = {:disable_sspi => 'foo'}
      expect{@winrm.disable_sspi}.to raise_error Dopi::CommandParsingError
    end
  end

  describe '#basic_auth_only' do
    it 'should return false if specified as false' do
      @winrm.hash = {:basic_auth_only => true}
      expect(@winrm.basic_auth_only).to be true
    end
    it 'should return true if not specified' do
      expect(@winrm.basic_auth_only).to be nil
    end
    it 'will raise and error if specified wrong' do
      @winrm.hash = {:basic_auth_only => 'foo'}
      expect{@winrm.basic_auth_only}.to raise_error Dopi::CommandParsingError
    end
  end



end
