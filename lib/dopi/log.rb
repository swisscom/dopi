#
# the logger stuff
#
require 'logger'

module Dopi

  def self.log
    @log ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @logger = logger
  end

end
