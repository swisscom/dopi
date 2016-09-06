#
# This class parses loades step sets
#
require 'yaml'
require 'dop_common'

module Dopi
  class StepSet
    include Dopi::State

    def initialize(parsed_step_set, plan)
      @parsed_step_set = parsed_step_set
      @plan = plan
      steps.each{|step| state_add_child(step)}
    end

    def name
      @parsed_step_set.name
    end

    def run(run_options)
      if state_done?
        Dopi.log.info("Step set #{name} is in state 'done'. Nothing to do")
        return
      end
      unless state_ready?
        raise StandardError, "Step set #{name} is not in state 'ready'. Try to reset the plan"
      end
      steps.each do |step|
        step.run(run_options)
        break if signals[:stop] || state_failed?
      end
    end

    # The main validation work is done in the dop_common
    # parser. We just add the command plugin parsers
    def valid?
      validity = true
      validity = false unless steps.all?{|step| step.valid? }
      validity
    rescue Dopi::NoRoleFoundError => e
      Dopi.log.warn(e.message)
    end

    def steps
      # Before all the new commands get parsed we have to make sure we
      # Reset all the plugin defaults
      PluginManager.plugin_klass_list('^dopi/command/').each do |plugin_klass|
        plugin_klass.wipe_plugin_defaults
      end
      @steps ||= @parsed_step_set.steps.map do |parsed_step|
        ::Dopi::Step.new(parsed_step, @plan)
      end
    end

    def load_state(state_hash)
      return if state_hash.empty?
      steps.each_with_index do |step, i|
        step.load_state(state_hash[i])
      end
    end

    def state_hash
      steps.map do |step|
        step.state_hash
      end
    end

  end
end
