
require 'spec_helper'

class ExitCodeTestKlass
  include Dopi::CommandParser::ExitCode
  attr_accessor :hash
end

module ExitCodeDefaults
  def expect_exit_codes_defaults
    [1,2,3]
  end
end

describe Dopi::CommandParser::ExitCode do

  describe '#expect_exit_codes' do
    subject do
      exit_code_parser = ExitCodeTestKlass.new
      exit_code_parser.hash = hash
      exit_code_parser.expect_exit_codes
    end

    context 'Nothing is specified' do
      let(:hash){nil}
      it{ is_expected.to eq(0) }
    end
    context 'A number is specified' do
      let(:hash){{:expect_exit_codes => 3}}
      it{ is_expected.to eq(3) }
    end
    context 'An Array is specified' do
      let(:hash){{:expect_exit_codes => [0, 1, 3]}}
      it{ is_expected.to eq([0, 1, 3]) }
    end
    context 'The :all keyword is specified' do
      let(:hash){{:expect_exit_codes => 'all'}}
      it{ is_expected.to eq('all') }
    end
    context 'The value is an invalid string' do
      let(:hash){{:expect_exit_codes => 'foo'}}
      it{ expect{subject}.to raise_error Dopi::CommandParsingError }
    end
    context 'The Array contains a String' do
      let(:hash){{:expect_exit_codes => [1, 2, 'foo']}}
      it{ expect{subject}.to raise_error Dopi::CommandParsingError }
    end
    context 'A plugin defaults method is specified' do
      subject do
        exit_code_parser = ExitCodeTestKlass.new
        exit_code_parser.extend(ExitCodeDefaults)
        exit_code_parser.expect_exit_codes
      end
      it{ is_expected.to eq([1,2,3])}
    end
  end

  describe 'check_exit_code' do
    pending
  end

end

