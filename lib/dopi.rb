require "dopi/error"
require "dopi/signal_handler"
require "dopi/configure"
require "dopi/log"
require "dopi/pluginmanager"
require "dopi/state"
require "dopi/command_parser/credentials"
require "dopi/exit_code_parser"
require "dopi/output_parser"
require "dopi/command"
require "dopi/command_set"
require "dopi/node"
require "dopi/node_filter"
require "dopi/plan"
require "dopi/step"
require "dopi/step_set"
require "dopi/version"

module Dopi

  class PlanSaver
    def initialize(plan)
      @plan = plan
    end

    def update
      Dopi.save_plan(@plan)
    end
  end

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
      if plan_exists?(plan_name)
        plan_dump = YAML::load(File.read(dump_file(plan_name)))
        if plan_dump.version == Dopi::VERSION
          return plan_dump
        else
          version = plan_dump.version || '< 0.5.1'
          raise StandardError,
            "Plan object version is #{version} while DOPi is version #{Dopi::VERSION}. Please run update."
        end
      else
        create(plan_name)
      end
    end

    def run_plan(plan, options)
      begin
        plan_saver = PlanSaver.new(plan)
        plan.add_observer(plan_saver)
        plan.run(options)
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
      plan_cache.update(plan_name) unless plan_cache.version(plan_name) == DopCommon::VERSION
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
