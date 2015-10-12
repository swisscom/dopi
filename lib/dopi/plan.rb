#
# This class loads a deployment plan
#
require 'forwardable'
require 'yaml'
require 'dop_common'

module Dopi
  class Plan
    extend Forwardable
    include Dopi::State

    attr_reader :plan_parser, :version

    def initialize(plan_parser)
      @version = Dopi::VERSION
      @mutex = Mutex.new
      @abort = false
      @plan_parser = plan_parser

      step_sets.each{|step_set| state_add_child(step_set)}
    end

    def_delegators :@plan_parser,
      :name,
      :configuration,
      :credentials,
      :ssh_root_pass,
      :max_in_flight,
      :canary_host

    def run(options = {})
      @mutex.synchronize { @abort = false }
      #set run option defaults
      options_defaults = {
        :run_for_nodes => :all,
        :noop          => false,
        :step_set      => 'default'
      }
      run_options = options_defaults.merge(options)
      step_set = step_sets.find{|s| s.name == run_options[:step_set]}
      raise "Plan: Step set #{run_options[:step_set]} does not exist" if step_set.nil?
      step_set.run(run_options)
    end

    def abort?
      @mutex.synchronize { @abort }
    end

    def abort!
      @mutex.synchronize do
        @abort = true
        step_sets.each do |step_set|
           step_set.abort! if step_set.state_running?
        end
      end
    end

    # The main validation work is done in the dop_common
    # parser. We just add the command plugin parsers
    def valid?
      validity = @plan_parser.valid?
      validity = false unless step_sets.all?{|step_set| step_set.valid? }
      validity
    rescue => e
      Dopi.configuration.trace ? Dopi.log.error(e) : Dopi.log.error(e.message)
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

  private

    def_delegator  :@plan_parser, :nodes,     :parsed_nodes
    def_delegator  :@plan_parser, :step_sets, :parsed_step_sets

  end
end
