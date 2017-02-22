#
# This class loads a deployment plan
#
require 'forwardable'
require 'yaml'
require 'dop_common'
require 'fileutils'

module Dopi
  class Plan
    extend Forwardable
    include Dopi::State

    attr_reader :plan_parser, :version

    def initialize(plan_parser)
      @version = Dopi::VERSION
      @plan_parser = plan_parser

      step_sets.each{|step_set| state_add_child(step_set)}
    end

    def_delegators :@plan_parser,
      :name,
      :configuration,
      :credentials,
      :max_in_flight,
      :max_per_role,
      :canary_host

    def run(options = {})
      init_file_logging
      #set run option defaults
      options_defaults = {
        :run_for_nodes => :all,
        :noop          => false,
        :step_set      => 'default',
        :node_info     => {},
      }
      run_options = options_defaults.merge(options)
      nodes.each{|node| node.node_info = run_options[:node_info][node.fqdn] || {}}
      step_set = step_sets.find{|s| s.name == run_options[:step_set]}
      raise "Plan: Step set #{run_options[:step_set]} does not exist" if step_set.nil?
      step_set.run(run_options)
    end

    def init_file_logging
      time = Time.now.strftime('%Y%m%d-%H%M%S')
      plan_log_path = File.join(DopCommon.config.log_dir, "#{time}-#{name}")
      FileUtils.mkdir_p(plan_log_path)
      create_file_log_device(plan_log_path, 'all')
      nodes.each {|node| create_file_log_device(plan_log_path, node.name)}
    end

    def create_file_log_device(path, context)
      log_file = File.join(path, context)
      Dopi::ContextLoggers.create_context_logger(log_file, context)
    end

    # The main validation work is done in the dop_common
    # parser. We just add the command plugin parsers
    def valid?
      validity = @plan_parser.valid?
      validity = false unless step_sets.all?{|step_set| step_set.valid? }
      validity
    rescue => e
      DopCommon.config.trace ? Dopi.log.error(e) : Dopi.log.error(e.message)
      Dopi.log.warn("Plan: Can't validate the command plugins because of a previous error")
    end

    def nodes
      @nodes ||= parsed_nodes.map do |parsed_node|
        ::Dopi::Node.new(parsed_node, self)
      end
    end

    def step_sets
      @step_sets ||= parsed_step_sets.map do |parsed_step_set|
        ::Dopi::StepSet.new(parsed_step_set, self)
      end
    end

    def load_state(state_hash)
      if state_hash[:step_sets].kind_of?(Hash)
        step_sets.each do |step_set|
          step_set_state = state_hash[:step_sets][step_set.name] || []
          step_set.load_state(step_set_state)
        end
      end
    end

    def state_hash
      step_sets_hash = {}
      step_sets.each do |step_set|
        step_sets_hash[step_set.name] = step_set.state_hash
      end
      {:step_sets => step_sets_hash}
    end

  private

    def_delegator  :@plan_parser, :nodes,     :parsed_nodes
    def_delegator  :@plan_parser, :step_sets, :parsed_step_sets

  end
end
