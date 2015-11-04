#
# Test the SignalHandler class
#
# This test was created with the help of the very useful blog post at
# http://timuruski.net/blog/2014/testing-signal-handlers/
#
require 'spec_helper'

describe Dopi::SignalHandler do

  it 'receives the signal, executes the block and then exits' do
    pipe_reader, pipe_writer = IO.pipe

    ruby = fork do
      pipe_reader.close
      Dopi::SignalHandler.new.handle_signals(:INT) do
        pipe_writer.puts('received')
        raise 'signal received'
      end
    end

    pipe_writer.close
    sleep(0.1)
    Process.kill(:INT, ruby)
    expect(pipe_reader.gets).to eq("received\n")
    pid, status = Process.waitpid2(ruby)
    expect(status.success?).to be true
  end

end

