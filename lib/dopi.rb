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

    def plan_valid?(plan_file)
      plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
      plan = Dopi::Plan.new(plan_parser)
      plan.valid?
    end

    def add_plan(plan_file)
      raise StandardError, 'Plan not valid; did not add' unless plan_valid?(plan_file)
      plan_name = plan_cache.add(plan_file)
      load_plan(plan_name)
    end

    def load_plan(plan_name)
      plan_exists?(plan_name) ? YAML::load(File.read(dump_file(plan_name))) : create(plan_name)
    end

    def run_plan(plan)
      begin
        run_thread    = Thread.new { plan.run }
        update_thread = Thread.new do
          until plan.state_done? or plan.state_failed? do
            Dopi.save_plan(plan) if plan.state_changed?
          end
          sleep(1)
        end
        run_thread.join
        update_thread.join
      ensure
        Dopi.save_plan(plan)
      end
    end

    def save_plan(plan)
      File.open(dump_file(plan.name), 'w') { |file| file.write(YAML::dump(plan)) }
    end

  private

    def plan_cache
      @plan_cache ||= DopCommon::PlanCache.new(Dopi.configuration.plan_cache_dir)
    end

    def plan_exists?(plan_name)
      File.exists?(dump_file(plan_name))
    end

    def create(plan_name)
      plan_parser = plan_cache.get(plan_name)
      plan = Dopi::Plan.new(plan_parser)
      raise StandardError, 'Plan not valid; did not add' unless plan.valid?
      save_plan(plan)
      plan
    end

    def dump_file(plan_name)
      File.join(Dopi.configuration.plan_cache_dir, plan_name + '_dopi.yaml')
    end

  end
end
