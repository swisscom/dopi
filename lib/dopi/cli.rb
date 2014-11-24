#
# Dopi cli
#
require 'thor'

module Dopi

  class Cli < Thor
    desc "nodes PLAN", "Lists all nodes in the plan"
    options Dopi.configuration.instance_variables
    def nodes(plan)
      Dopi.configure {}
      plan = Plan.new( File.read( plan ) )
      plan.nodes.each do |node|
        puts node.fqdn + ' : ' + node.role
      end
    end
  end

end
