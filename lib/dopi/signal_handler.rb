#
# Defered signal handling
#
# This class will handle the trapping of signals
#
# This code uses tricks from http://timuruski.net/blog/2014/graceful-shutdown
# for setup and teardown of the signal handlers. And the self pipe trick from
# http://www.sitepoint.com/the-self-pipe-trick-explained
#

module Dopi
  class SignalHandler
    DEFAULT_SIGNALS = [:INT, :QUIT, :TERM]

    def initialize
      @signal_queue = []
      @self_reader, @self_writer = IO.pipe
    end

    def handle_signals(*signals)
      signals = DEFAULT_SIGNALS if signals.empty?
      old_handlers = setup_signal_traps(signals)
      loop do
        begin
          if @signal_queue.any?
            yield(@signal_queue.shift) if block_given?
          else
            IO.select([@self_reader])
            @self_reader.read_nonblock(1)
          end
        rescue
          break
        end
      end
      teardown_signal_traps(old_handlers)
    end

    private

    def setup_signal_traps(signals)
      signals.each_with_object({}) do |signal, old_handlers|
        old_handlers[signal] = Signal.trap(signal) do
          @signal_queue << { signal => Time.now }
          @self_writer.write_nonblock('.')
        end
      end
    end

    def teardown_signal_traps(old_handlers)
      old_handlers.each do |signal, old_handler|
        Signal.trap(signal, old_handler)
      end
    end

  end
end
