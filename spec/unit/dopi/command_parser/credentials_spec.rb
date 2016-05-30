require 'spec_helper'

class CredentialsTestKlass
  include Dopi::CommandParser::Credentials
  attr_accessor :hash, :step
  def supported_credential_types() [:username_password] end
end

describe Dopi::CommandParser::Credentials do

  before :each do
    @credentials = CredentialsTestKlass.new
    @fake_credentials  = instance_double('DopCommon::Credentials', :type => :username_password)
    @fake_credentials4 = instance_double('DopCommon::Credentials', :type => :non_existing_type)
    plan = instance_double('Dopi::Plan', :credentials => {
      'test_credentials_01' => @fake_credentials,
      'test_credentials_02' => @fake_credentials,
      'test_credentials_04' => @fake_credentials4
    })
    @credentials.step = instance_double('Dopi::Step', :plan => plan)
  end

  describe '#credentials' do
    it 'returns an empty array if nothing is specified' do
      @credentials.hash = {}
      expect(@credentials.credentials).to eq([])
    end
    it 'returns an array with one credential if only one is specified' do
      @credentials.hash = {:credentials => 'test_credentials_01'}
      expect(@credentials.credentials.length).to eq(1)
      expect(@credentials.credentials.first).to be @fake_credentials
    end
    it 'returns an array with two credentials if two are specified' do
      @credentials.hash = {:credentials => ['test_credentials_01', 'test_credentials_02']}
      expect(@credentials.credentials.length).to eq(2)
      expect(@credentials.credentials.last).to be @fake_credentials
    end
    it 'raises an error if the credentials are not valid' do
      @credentials.hash = {:credentials => ['test_credentials_01', 2]}
      expect{@credentials.credentials}.to raise_error Dopi::CommandParsingError
    end
    it 'raises an error if the credentials do not exist' do
      @credentials.hash = {:credentials => ['test_credentials_01', 'test_credentials_03']}
      expect{@credentials.credentials}.to raise_error Dopi::CommandParsingError
    end
    it 'raises an error if one of the credential types is not supported' do
      @credentials.hash = {:credentials => ['test_credentials_01', 'test_credentials_04']}
      expect{@credentials.credentials}.to raise_error Dopi::CommandParsingError
    end
  end

end

