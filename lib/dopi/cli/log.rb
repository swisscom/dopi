#
# Initializes the logger for the CLI
#
module Dopi
  module Cli

    class CustomFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        "#{msg2str(msg)}\n"
      end
    end

    def self.initialize_logger(log_level, verbosity)
      # create a dummy logger and use the lowest log level configured
      Dopi.logger = Logger.new('/dev/null')
      file_log_level = ::Logger.const_get(log_level.upcase)
      cli_log_level = ::Logger.const_get(verbosity.upcase)
      min_log_level = file_log_level < cli_log_level ? file_log_level : cli_log_level
      Dopi.log.level = min_log_level

      # create the cli logger
      logger = Logger.new(STDOUT)
      logger.level = cli_log_level
      logger.formatter = CustomFormatter.new
      DopCommon.add_log_junction(logger)

      # init file logger
      Dopi.init_file_logger
    end

    def self.state(plan)
      result = "[#{plan.state.to_s}] #{plan.name}\n"
      plan.step_sets.each do |step_set|
        result << "  [#{step_set.state.to_s}] #{step_set.name}\n"
        step_set.steps.each do |step|
          result << "    [#{step.state.to_s}] #{step.name}\n"
          step.commands.each do |command|
            result << "      [#{command.state.to_s}] #{command.node.name}\n"
          end
        end
      end
      return result
    end

    def self.print_state(plan)
      puts state(plan)
    end

  end
end
