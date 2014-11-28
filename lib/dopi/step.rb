#
# Step
#
 
module Dopi

  class Step
    attr_reader :name, :nodes, :command    

    def initialize(name, nodes, command)
      @name = name
      @nodes = nodes
      @command = command 
    end

  end

end
