require 'spec_helper'

class OutputTestKlass
  include Dopi::CommandParser::Output
  attr_accessor :hash
  def log(s,m); end
end

describe Dopi::CommandParser::Output do

  before :each do
    @output_parser = OutputTestKlass.new
  end

  describe 'parse_output' do
    it 'Returns an empty hash if nothing is defined' do
      expect(@output_parser.parse_output).to eq({})
    end
    it 'Returns the correct hash if one is defined' do
      @output_parser.hash = {:parse_output => {:error => [], :warning => []}}
      expect(@output_parser.parse_output).to eq({:error => [], :warning => []})
    end
    it 'Raises an exeption if the value is not a hash' do
      @output_parser.hash = {:parse_output => 2}
      expect{@output_parser.parse_output}.to raise_error Dopi::CommandParsingError
    end
  end

  describe 'error_patterns' do
     it 'Returns an empty array if nothing is defined' do
      expect(@output_parser.error_patterns).to eq([])
    end
    it 'Returns the correct array if it is specified' do
      @output_parser.hash = {:parse_output => {:error => [ 'foo', '^bar$' ]}}
      expect(@output_parser.error_patterns).to eq([ 'foo', '^bar$' ])
    end
    it 'Raises an exeption if the value is not an array' do
      @output_parser.hash = {:parse_output => {:error => 2}}
      expect{@output_parser.error_patterns}.to raise_error Dopi::CommandParsingError
    end
    it 'Raises an exception if the pattern is not a Regular Expression' do
      @output_parser.hash = {:parse_output => {:error => ['][']}}
      expect{@output_parser.error_patterns}.to raise_error Dopi::CommandParsingError
    end
  end

  describe 'warning_patterns' do
     it 'Returns an empty array if nothing is defined' do
      expect(@output_parser.warning_patterns).to eq([])
    end
    it 'Returns the correct array if it is specified' do
      @output_parser.hash = {:parse_output => {:warning => [ 'foo', '^bar$' ]}}
      expect(@output_parser.warning_patterns).to eq([ 'foo', '^bar$' ])
    end
    it 'Raises an exeption if the value is not an array' do
      @output_parser.hash = {:parse_output => {:warning => 2}}
      expect{@output_parser.warning_patterns}.to raise_error Dopi::CommandParsingError
    end
  end

  describe 'fail_on_warning' do
     it 'Returns false if nothing is defined' do
      expect(@output_parser.fail_on_warning).to be false
    end
    it 'Returns true if specified' do
      @output_parser.hash = {:fail_on_warning => true}
      expect(@output_parser.fail_on_warning).to be true
    end
    it 'Returns false if specified' do
      @output_parser.hash = {:fail_on_warning => false}
      expect(@output_parser.fail_on_warning).to be false
    end
    it 'Raises an exeption if the value is not a boolean' do
      @output_parser.hash = {:fail_on_warning => 2}
      expect{@output_parser.fail_on_warning}.to raise_error Dopi::CommandParsingError
    end
  end

  describe 'check_output' do
    it 'Returns true if no error is detected' do
      raw_output = <<-OUTPUT
        Foo
        Bar
      OUTPUT
      @output_parser.hash = {:parse_output => {:error => [ 'Error:' ]}}
      expect(@output_parser.check_output(raw_output)).to be true
    end
    it 'Returns false if an error is detected' do
      raw_output = <<-OUTPUT
        Foo
        Error: this is a fake error
        Bar
      OUTPUT
      @output_parser.hash = {:parse_output => {:error => [ 'Error:' ]}}
      expect(@output_parser.check_output(raw_output)).to be false
    end
    it 'Returns true if no warning is detected' do
      raw_output = <<-OUTPUT
        Foo
        Bar
      OUTPUT
      @output_parser.hash = {:parse_output => {:warning => [ 'Warning:' ]}}
      expect(@output_parser.check_output(raw_output)).to be true
    end
    it 'Returns true if an warning is detected but fail_on_warning is not true' do
      raw_output = <<-OUTPUT
        Foo
        Warning: this is a fake error
        Bar
      OUTPUT
      @output_parser.hash = {:parse_output => {:warning => [ 'Warning:' ]}}
      expect(@output_parser.check_output(raw_output)).to be true
    end
    it 'Returns true if an warning is detected but fail_on_warning is not true' do
      raw_output = <<-OUTPUT
        Foo
        Warning: this is a fake error
        Bar
      OUTPUT
      @output_parser.hash = {
        :fail_on_warning => true,
        :parse_output => {:warning => [ 'Warning:' ]}
      }
      expect(@output_parser.check_output(raw_output)).to be false
    end
  end

end

