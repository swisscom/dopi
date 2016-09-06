#
#
# This class represents the set commands for a
# specific node and step.
#
# It will also manage the run group restrictions
#

module Dopi
  class CommandSet
    include Dopi::State
    attr_reader :plan, :step, :node

    def initialize(step_parser, step, node)
      @step_parser = step_parser
      @step = step
      @plan = step.plan
      @node = node

      commands.each{|command| state_add_child(command)}
    end

    def name
      @node.name
    end

    def commands
      @commands ||= @step_parser.commands.map do |command|
        Dopi::Command.create_plugin_instance(command, @step, node)
      end
    end

    def valid?
      begin
        commands.all?{|command| command.meta_valid?}
      rescue PluginLoaderError => e
        Dopi.log.error("Step '#{name}': Can't load plugin : #{e.message}")
        false
      end
    end

    def run(noop)
      commands.each do |command|
        break if state_failed? or signals[:stop]
        command.meta_run(noop)
        break unless command.state_done?
      end
    end

    def load_state(state_hash)
      return if state_hash.empty?
      commands.each_with_index do |command, i|
        command.load_state(state_hash[i])
      end
    end

    def state_hash
      commands.map do |command|
        command.state_hash
      end
    end

  end
end


