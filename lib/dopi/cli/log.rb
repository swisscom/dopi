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

  end
end
