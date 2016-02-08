module Dopi
  module Cli

    def self.command_update(base)
      base.class_eval do

        desc 'Update a plan in the plan cache (WARNING: This will reset all the saved states in the plan)'
        arg_name 'plan_file'
        command :update do |c|
          c.desc 'Update the plan with a new plan yaml file'
          c.arg_name 'PLANFILE'
          c.flag [:plan]

          c.action do |global_options,options,args|
            help_now!('Specify a plan id to update') if args.empty?
            help_now!('You can only update one plan') if args.length > 1
            puts @plan_cache.update(args[0], options[:plan])
          end
        end

      end
    end

  end
end

