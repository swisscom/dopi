require "dopi/configure"
require "dopi/log"
require "dopi/pluginmanager"
require "dopi/state"
require "dopi/exit_code_parser"
require "dopi/output_parser"
require "dopi/command"
require "dopi/node"
require "dopi/plan"
require "dopi/step"
require "dopi/version"

module Dopi
  class << self

    def load_plan(plan_id)
      plan_exists?(plan_id) ? YAML::load(File.read(dump_file(plan_id))) : create(plan_id)
    end

    def save_plan(plan)
      File.open(dump_file(plan.id), 'w') { |file| file.write(YAML::dump(plan)) }
    end

  private

    def plan_cache
      @plan_cache ||= DopCommon::PlanCache.new(Dopi.configuration.plan_cache_dir)
    end

    def plan_exists?(plan_id)
      File.exists?(dump_file(plan_id))
    end

    def create(plan_id)
      plan_parser = plan_cache.get(plan_id)
      plan = Dopi::Plan.new(plan_parser, plan_id)
      raise StandardError, 'Plan not valid; did not add' unless plan.valid?
      save_plan(plan)
      plan
    end

    def dump_file(plan_id)
      File.join(Dopi.configuration.plan_cache_dir, plan_id + '_dopi.yaml')
    end

  end
end
