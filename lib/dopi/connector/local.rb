#
# This connector simply executes commands on the local
# machine. It does all the signal handling and makes
# sure processes are stopped or killed.
#
require 'pty'
require 'open3'

module Dopi
  module Connector
    module Local

      # The command method executes the command of the step.
      # Returns an array with stdio, sterror and exit code.
      def local_command(env, command_string)
        master, slave = PTY.open
        stdout_r, stdout_w = IO.pipe
        stderr_r, stderr_w = IO.pipe
        cmd_stdout = ''
        cmd_stderr = ''
        options = {
          :pgroup          => true,
          :unsetenv_others => true,
          :in              => slave,
          :out             => stdout_w,
          :err             => stderr_w,
        }
        log(:debug, "Executing #{command_string} for command #{name}")
        log(:debug, "Environment: #{env.to_s}")

        pid = Process.spawn(merged_env(env), command_string, options)
        slave.close
        stdout_w.close
        stderr_w.close

        signal_handler = Proc.new do |signal|
          case signal
          when :abort then Process.kill(:TERM, pid)
          when :kill  then Process.kill(:KILL, pid)
          end
        end

        on_signal(signal_handler)
        stdout_thread = Thread.new do
          until ( line = stdout_r.gets ).nil? do
            cmd_stdout << line
            log(:debug, line.gsub("\n", '').gsub("\r", ''))
          end
        end

        stderr_thread = Thread.new do
          until ( line = stderr_r.gets ).nil? do
            cmd_stderr << line
            log(:error, line.gsub("\n", '').gsub("\r", ''))
          end
        end

        _, status = Process.wait2(pid)
        stdout_thread.join
        stderr_thread.join
        delete_on_signal(signal_handler)
        [ cmd_stdout, cmd_stderr, status.exitstatus ]
      end

    private

      def merged_env(env)
        {
          'HOME' => ENV['HOME'],
          'PATH' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
        }.merge(env)
      end

    end
  end
end

