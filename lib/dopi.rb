require "dopi/cli"
require "dopi/configure"
require "dopi/node"
require "dopi/plan"
require "dopi/version"


module Dopi

  def self.log
    @log ||= Logger.new(STDOUT)
  end

end
