module Dopi
  module Cli

    def self.run_options(command)
      node_select_options(command)

      command.desc 'Show only stuff the run would do but don\'t execute commands (verify commands will still be executed)'
      command.default_value false
      command.switch [:noop, :n]

      command.desc 'Select the step set to run (if nothing is specified it will try to run the step set "default")'
      command.default_value 'default'
      command.arg_name 'STEPSET'
      command.flag [:step_set, :s]
    end

    def self.command_run(base)
      base.class_eval do

        desc 'Run the plan'
        arg_name 'id'
        command :run do |c|
          run_options(c)
          c.action do |global_options,options,args|
            help_now!('Specify a plan name to run') if args.empty?
            help_now!('You can only run one plan') if args.length > 1
            options[:run_for_nodes] = parse_node_select_options(options)
            plan = Dopi.load_plan(args[0])
            run_signal_handler(plan)
            begin
              Dopi.run_plan(plan, options)
            rescue Dopi::StateTransitionError => e
              Dopi.log.error(e.message)
              exit_now!("Some steps are in a state where they can't be started again. Try to reset the plan.")
            ensure
              print_state(plan)
              exit_now!('Errors during plan run detected!') if plan.state_failed?
            end
          end
        end

        desc 'Add a plan, run it and then remove it again (This is mainly for testing)'
        arg_name 'plan_file'
        command :oneshot do |c|
          run_options(c)
          c.action do |global_options,options,args|
            help_now!('Specify a plan file to add') if args.empty?
            help_now!('You can only add one plan') if args.length > 1
            options[:run_for_nodes] = parse_node_select_options(options)
            begin
              plan = Dopi.add_plan(args[0])
              run_signal_handler(plan)
              begin
                Dopi.run_plan(plan, options)
                sleep(2) # allow the show command to catch up
              ensure
                print_state(plan)
                exit_now!('Errors during plan run detected!') if plan.state_failed?
              end
            ensure @plan_cache.remove(plan.name) unless plan.nil?
            end
          end
        end

      end
    end

  end
end


