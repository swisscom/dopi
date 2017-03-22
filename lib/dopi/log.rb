#
# the logger stuff
#
require 'logger'
require 'dop_common/log'

module Dopi

  def self.log
    @log ||= DopCommon.log
  end

  def self.logger=(logger)
    @log = logger
    DopCommon.logger = logger
  end

end
