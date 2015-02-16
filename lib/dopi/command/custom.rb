#
# DOPi command base class
#
require 'open3'

module Dopi
  class Command
    class Custom < Dopi::Command

    public

      def run
        result = []
        cmd_stdout, cmd_stderr, cmd_exit_code = run_command
        result << parse_output(cmd_stdout)
        result << parse_output(cmd_stderr)
        result << check_exit_code(cmd_exit_code)
        result.all?
      end

    private

      def env
        env = hash['env']
        env ||= {}
      end


      def arguments
        arguments = hash['arguments']
        arguments ||= {}
      end


      def argument_string
        arguments.flatten.join(' ')
      end


      def exec
        if hash['exec']
          return hash['exec']
        else
          raise "No exec part for command #{name}"
        end
      end


      def command_string
        exec + ' ' + argument_string
      end


      # The command method executes the command of the step.
      # Returns an array with stdio, sterror and exit code.
      def run_command
        cmd_stdout = ''
        cmd_stderr = ''
        Dopi.log.debug("Executing #{command_string} for command #{name}")
        cmd_exit_code = Open3.popen3(env, command_string) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          cmd_stdout = stdout.read
          cmd_stderr = stderr.read
          Dopi.log.debug(@node.name + ":" + name + " - " + cmd_stdout)
          Dopi.log.debug(@node.name + ":" + name + " - " + cmd_stderr)
          wait_thr.value
        end
        [ cmd_stdout, cmd_stderr, cmd_exit_code.exitstatus ]
      end


      # Return parser patterns if you want to hardcode
      # it to the command. This can be overwritten by
      # the 'parse_output' section in the plan
      def parser_patterns
        nil 
      end


      # Parse the raw_output
      def parse_output(raw_output)
        errors = []
        warnings = []
        patterns = nil

        if parser_patterns.class == Hash
          patterns = parser_patterns
        end
        if hash['parse_output'].class == Hash
          patterns = hash['parse_output']
        end
        if patterns.nil?
          Dopi.log.debug("No patterns defined to parse the output of command #{name}")
          return true
        else
          if patterns['error'].class == Array
            errors = match_patterns(raw_output, patterns['error'])
            errors.each do |error|
              Dopi.log.error("ERROR detected in output of command #{name}:")
              Dopi.log.error(error)
            end
          end
          if patterns['warning'].class == Array
            warnings = match_patterns(raw_output, patterns['warning'])
            warnings.each do |warning|
              Dopi.log.warn("Warning detected in output of command #{name}:")
              Dopi.log.warn(warning)
            end
          end
        end
        if @command_hash['fail_on_warning']
          return false unless warnings.empty?
        end
        return false unless errors.empty?
        return true
      end

      
      # takes an array of patterns and a string to match
      # returns every line with a match
      def match_patterns(raw_output, patterns)
        results = []
        patterns.each do |pattern|
          begin
            regexp = Regexp.new(pattern)
            raw_output.each_line do |line|
              results << line unless line.scan(regexp).empty?
            end
          rescue RegexpError => e
            # TODO: Throw proper exception class
            raise "Error while parsing regular expression #{pattern} for command #{name}"
          end
        end
        return results
      end

      

      # Returns an array of valid exit codes or
      def expect_exit_codes
        exit_code = [ 0 ]
        if hash['expect_exit_code'].class == Fixnum
          exit_code = [ hash['expect_exit_code'] ]
        elsif hash['expect_exit_code'].class == Array
          exit_code = hash['expect_exit_code']
        elsif hash['expect_exit_code'].class == String
          if hash['expect_exit_code'].casecmp('all') == 0
            exit_code = nil
          end
        end
        return exit_code
      end


      def check_exit_code(cmd_exit_code)
        return true unless expect_exit_codes
        if expect_exit_codes.include? cmd_exit_code
          return true
        else
          Dopi.log.error("Wrong exit code in command #{name} for node #{@node.name}")
          Dopi.log.error("Exit code was #{cmd_exit_code.to_s} should be one of #{expect_exit_codes.join(',')}")
          return false
        end
      end


    end
  end
end
