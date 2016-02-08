module Dopi
  module Cli

    def self.run_signal_handler(plan)
      plan.reset_signals
      signal_handler_thread = Thread.new do
        Dopi.log.info("Starting signal handling")
        signal_counter = 0
        Dopi::SignalHandler.new.handle_signals(:INT, :TERM) do
          signal_counter += 1
          case signal_counter
          when 1
            Dopi.log.warn("Signal received! The run will halt after all currently running commands are finished")
            plan.send_signal(:stop)
          when 2
            Dopi.log.error("Signal received! Sending termination signal to all the processes!")
            plan.send_signal(:abort)
          when 3
            Dopi.log.error("Signal received! Sending KILL signal to all the processes!")
            plan.send_signal(:kill)
          end
        end
      end
      signal_handler_thread.abort_on_exception = true
    end

  end
end

