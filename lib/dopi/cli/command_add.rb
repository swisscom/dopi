module Dopi
  module Cli

    def self.command_add(base)
      base.class_eval do

        desc 'Add a new plan file to the plan cache'
        arg_name 'plan_file'
        command :add do |c|
          c.desc 'update the plan if it already exists'
          c.default_value false
          c.switch [:update, :u]

          c.action do |global_options,options,args|
            help_now!('Specify a plan file to add') if args.empty?
            help_now!('You can only add one plan') if args.length > 1
            plan_file = args[0]
            begin
              puts Dopi.add(plan_file)
            rescue DopCommon::PlanExistsError => e
              if options[:update]
                puts Dopi.update_plan(plan_file, {})
              else
                raise e
              end
						end
          end
        end

      end
    end

  end
end

