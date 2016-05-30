#
# This connector simply executes commands on the local
# machine. It does all the signal handling and makes
# sure processes are stopped or killed.
#
module Dopi
  module Connector
    module Local

      # The command method executes the command of the step.
      # Returns an array with stdio, sterror and exit code.
      def local_command(env, command_string)
        cmd_stdout = ''
        cmd_stderr = ''
        log(:debug, "Executing #{command_string} for command #{name}")
        log(:debug, "Environment: #{env.to_s}")
        cmd_exit_code = Open3.popen3(env, command_string, :pgroup => true) do |stdin, stdout, stderr, wait_thr|
          signal_handler = Proc.new do |signal|
            case signal
            when :abort then Process.kill(:TERM, wait_thr.pid)
            when :kill  then Process.kill(:KILL, wait_thr.pid)
            end
          end
          on_signal(signal_handler)
          stdin.close
          stdout_thread = Thread.new do
            until ( line = stdout.gets ).nil? do
              cmd_stdout << line
              log(:debug, line.gsub("\n", '').gsub("\r", ''))
            end
          end
          stderr_thread = Thread.new do
            until ( line = stderr.gets ).nil? do
              cmd_stderr << line
              log(:error, line.gsub("\n", '').gsub("\r", ''))
            end
          end
          exit_status = wait_thr.value
          stdout_thread.join
          stderr_thread.join
          delete_on_signal(signal_handler)
          exit_status
        end
        [ cmd_stdout, cmd_stderr, cmd_exit_code.exitstatus ]
      end

    end
  end
end

