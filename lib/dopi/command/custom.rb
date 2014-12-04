#
# DOPi command base class
#
require 'open3'

module Dopi
  class Command
    class Custom < Dopi::Command

      attr_reader :node, :name, :state, :command_hash

    public

      def initialize(node, command_hash = nil)
        @state = :ready
        @node = node

        if command_hash.class == String
          @name = command_hash
          @command_hash = {}
        elsif command_hash.class == Hash
          @name = command_hash['name']
          @command_hash = command_hash
        else
          # TODO: throw proper exception class
          raise "The command in a step has to be a String or a Hash"
        end
      end


      def run
        Dopi.log.debug("Running command #{@name} on #{@node.fqdn}")
        begin 
          # verify state if needed first
          if @state == :ready && @command_hash['dop_verify_cmd']
            @state = :done if dop_verify
          end
          if @state == :ready && @command_hash['node_verify_cmd']
            @state = :done if node_verify
          end
          if @state == :ready
            cmd_stdout, cmd_stderr, cmd_exit_code = command
            @state = :failed unless parse_output(cmd_stdout)
            @state = :failed unless parse_output(cmd_stderr)
            @state = :failed unless check_exit_code(cmd_exit_code)
            @state = :done   unless @state == :failed
          else
            Dopi.log.info("Nothing to do for command #{@name}")
          end
        rescue Exception => e
          Dopi.log.error("An error occured when executing #{@name}")
          @state = :failed
          raise e
        end
      end


    private


      def dop_verify
        # TODO: implement
        false
      end


      def node_verify
        # TODO: implement
        false
      end


      # The command method executes the command of the step.
      # Returns an array with stdio, sterror and exit code.
      def command
        if @command_hash['exec']
          # TODO: arguments
          #arguments = @command_hash['arguments']
          #arguments ||= ''
          env = @command_hash['env']
          env ||= {}
          command_string = @command_hash['exec'] #+ ' ' + arguments

          cmd_stdout = ''
          cmd_stderr = ''
          cmd_exit_code = Open3.popen3(env, command_string) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            cmd_stdout = stdout.read
            cmd_stderr = stderr.read
            Dopi.log.debug(@node.fqdn + ":" + @name + " - " + cmd_stdout)
            Dopi.log.debug(@node.fqdn + ":" + @name + " - " + cmd_stderr)
            wait_thr.value
          end
          return cmd_stdout, cmd_stderr, cmd_exit_code
        else
          raise "No exec part for command #{@name}"
        end
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
        if @command_hash['parse_output'].class == Hash
          patterns = @command_hash['parse_output']
        end
        if patterns.nil?
          Dopi.log.debug("No patterns defined to parse the output of command #{@name}")
          return true
        else
          if patterns['error'].class == Array
            errors = match_patterns(raw_output, patterns['error'])
            errors.each do |error|
              Dopi.log.error("ERROR detected in output of command #{@name}:")
              Dopi.log.error(error)
            end
          end
          if patterns['warning'].class == Array
            warnings = match_patterns(raw_output, patterns['warning'])
            warnings.each do |warning|
              Dopi.log.warn("Warning detected in output of command #{@name}:")
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
            raise "Error while parsing regular expression #{pattern} for command #{@name}"
          end
        end
        return results
      end


      def check_exit_code(cmd_exit_code)
        # TODO: implement
        # @command_hash['expect_exit_code']
        return true
      end


    end
  end
end
