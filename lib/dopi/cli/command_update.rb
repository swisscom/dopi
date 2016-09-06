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
            plan_name = args[0]
            if options[:plan]
              Dopi.update_plan(options[:plan], options)
            else
              Dopi.update_state(plan_name, options)
            end
          end
        end

      end
    end

  end
end

