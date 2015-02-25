#
# This will manage a Dopi plan cache where you can add, remove and run plans
#

module Dopi
  class Cache

    def initialize(plan_dir) 
      @plan_dir = plan_dir

      # make sure the plan directory is created
      FileUtils.mkdir_p(@plan_dir) unless File.directory?(@plan_dir)
    end

    def add(plan_file)
      id = Dopi::Plan.get_id_from_file(plan_file)
      raise StandardError, 'Plan was already added. Remove to readd the plan' if id_exists?(id)

      plan = Dopi::Plan.create_plan_from_file(plan_file)
      raise StandardError, 'Plan not valid, did not add' unless plan.valid?

      File.open(dump_file(id), 'w') { |file| file.write(YAML::dump(plan)) }
      Dopi.log.info("New plan #{plan_file} was added with id #{id}")
      id
    end

    def list
      Dir[File.join(@plan_dir, '*_plan.yaml')].map do |file|
        File.basename(file).sub('_plan.yaml', '')
      end
    end

    def remove(id)
      raise StandardError, 'Plan id does not exist' unless id_exists?(id)
      FileUtils.rm(dump_file(id))
      Dopi.log.info("Plan with id #{id} was removed")
      id
    end

    def get(id)
      raise StandardError, 'Plan id does not exist' unless id_exists?(id)
      YAML::load(File.read(dump_file(id)))
    end

  private

    def id_exists?(id)
      File.exists?(dump_file(id))
    end

    def dump_file(id)
      File.join(@plan_dir, id + '_plan.yaml')
    end
  
  end
end
