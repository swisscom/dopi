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

end
