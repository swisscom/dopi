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

    def_delegators :@step_parser, :name, :canary_host

    def run(max_in_flight)
      state_run
      commands_copy = commands.dup
      if canary_host
        pick = rand(commands_copy.length - 1)
        commands_copy.delete_at(pick).meta_run
      end
      unless state_failed?
        Parallel.each(commands_copy, :in_threads => max_in_flight) do |command|
          raise Parallel::Break if state_failed?
          command.meta_run
        end
      end
    end

    def command_plugin_valid?
      dummy_node = Dopi::Node.new(DopCommon::Node('dummy.example.com', {}))
      begin
        command = Dopi::Command.create_plugin_instance(@step_parser.command.plugin, dummy_node, @step_parser.command)
        return command.meta_valid?
      rescue PluginLoaderError => e
        Dopi.log.error("Step #{name}: Can't load plugin #{@tep_parser.command.plugin}: #{e.message}")
        return false
      end
    end

    def commands
      @commands ||= @nodes.map do |node|
        Dopi::Command.create_plugin_instance(@step_parser.command.plugin, node, @step_parser.command)
      end
    end

  end
end
