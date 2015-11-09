#
# the logger stuff
#
require 'logger'
require 'dop_common'

module Dopi

  def self.log
    @log ||= Dopi.logger = Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @log = logger
    DopCommon.logger = logger
  end

  def self.init_file_logger
    log_file = File.join(Dopi.configuration.log_dir, 'dopi.log')
    logger = Logger.new(log_file , 10, 1024000)
    logger.level = ::Logger.const_get(Dopi.configuration.log_level.upcase)
    logger.formatter = file_logger_formatter
    DopCommon.add_log_junction(logger)
  end

  def self.file_logger_formatter
    Proc.new do |severity, datetime, progname, msg|
      ContextLoggers.log(severity, datetime, msg, progname)
    end
  end

  class ContextLoggers
    @mutex = Mutex.new
    @context_loggers = {}
    @log_contexts = {}
    @original_formatter = Logger::Formatter.new

    def self.log_context=(context)
      @mutex.synchronize do
        @log_contexts[Thread.current.object_id.to_s] = context
      end
    end

    def self.log(severity, datetime, msg, progname)
      @mutex.synchronize do
        @context_loggers.each do |filter_context, context_logger|
          if filter_context == 'all' || log_context == filter_context
            context_logger.log(::Logger.const_get(severity), msg, progname)
          end
        end
        @original_formatter.call(severity, datetime, progname, msg)
      end
    end

    def self.create_context_logger(logdev, filter_context)
      @mutex.synchronize do
        logger = Logger.new(logdev)
        logger.level = ::Logger.const_get(Dopi.configuration.log_level.upcase)
        @context_loggers[filter_context] = logger
      end
    end

    private

    def self.log_context
      @log_contexts[Thread.current.object_id.to_s] or 'global'
    end

  end
end
