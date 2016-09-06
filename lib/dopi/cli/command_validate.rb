module Dopi
  module Cli

    def self.command_validate(base)
      base.class_eval do

        desc 'Validate a plan file'
        arg_name 'plan_file'
        command :validate do |c|
          c.action do |global_options,options,args|
            help_now!('Specify a plan file to add') if args.empty?
            help_now!('You can only add one plan') if args.length > 1
            plan_file = args[0]
            if Dopi.valid?(plan_file)
              puts "Plan is valid"
            else
              exit_now!("Plan is NOT valid")
            end
          end
        end

      end
    end

  end
end

