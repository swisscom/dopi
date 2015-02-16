#
# Step
#
require 'forwardable'
require 'parallel'

module Dopi
  class Step
    extend Forwardable
    include Dopi::State

    def initialize(step_parser, nodes = [])
      @step_parser = step_parser
      @nodes = nodes

      commands.each{|command| state_add_child(command)}
      raise "nodes list for step #{name} is empty" if @nodes.empty?
    end

    def_delegators :@step_parser, :name

    def run(max_in_flight)
      state_run
      Parallel.each(commands, in_threads: max_in_flight) do |command|
        raise Parallel::Break if state_failed?
        command.meta_run
      end
    end

    def commands
      @commands ||= @nodes.map do |node|
        Dopi::Command.create_plugin_instance(@step_parser.command.plugin, node, @step_parser.command)
      end
    end

  end
end
