#
# The DOPi CLI main module
#
require 'gli'
require 'dopi'
require 'dopi/cli/global_options'
require 'logger/colors'
require 'curses'
require 'yaml'
require 'fileutils'

module Dopi
  module Cli
    include GLI::App
    extend self

    program_desc 'DOPi Command line Client'
    version Dopi::VERSION

    subcommand_option_handling :normal
    arguments :strict

    config_file Dopi.configuration.config_file

    desc 'Verbosity of the command line tool'
    default_value 'INFO'
    arg_name 'Verbosity'
    flag [:verbosity, :v]

    include Dopi::Cli::GlobalOptions

    pre do |global,command,options,args|
      Dopi.configure do |config|
        config.trace =              global[:trace]
        config.plan_cache_dir =     global[:plan_cache_dir]
        config.use_hiera =          global[:use_hiera]
        config.hiera_yaml =         global[:hiera_yaml]
        config.facts_dir =          global[:facts_dir]
        config.load_facts =         global[:load_facts]
        config.role_variable =      global[:role_variable]
        config.role_default =       global[:role_default]
        config.ssh_user =           global[:ssh_user]
        config.ssh_key =            global[:ssh_key]
        config.ssh_pass_auth =      global[:ssh_pass_auth]
        config.ssh_check_host_key = global[:ssh_check_host_key]
        config.mco_config         = global[:mco_config]
        config.mco_dopi_logger    = global[:mco_dopi_logger]
        config.log_dir            = global[:log_dir]
        config.log_level          = global[:log_level]
        config.connection_check_timeout = global[:connection_check_timeout]
      end
      ENV['GLI_DEBUG'] = 'true' if global[:trace] == true
      # create a dummy logger and use the lowest log level configured
      Dopi.logger = Logger.new('/dev/null')
      file_log_level = ::Logger.const_get(global[:log_level].upcase)
      cli_log_level = ::Logger.const_get(global[:verbosity].upcase)
      min_log_level = file_log_level < cli_log_level ? file_log_level : cli_log_level
      Dopi.log.level = min_log_level

      # create the cli logger
      logger = Logger.new(STDOUT)
      logger.level = cli_log_level
      logger.formatter = CustomFormatter.new
      DopCommon.add_log_junction(logger)


      Dopi.init_file_logger # init file logger
      @plan_cache = DopCommon::PlanCache.new(global[:plan_cache_dir])
      true
    end

    class CustomFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        "#{msg2str(msg)}\n"
      end
    end

    def state(plan)
      result = "[#{plan.state.to_s}] #{plan.name}\n"
      plan.step_sets.each do |step_set|
        result << "  [#{step_set.state.to_s}] #{step_set.name}\n"
        step_set.steps.each do |step|
          result << "    [#{step.state.to_s}] #{step.name}\n"
          step.commands.each do |command|
            result << "      [#{command.state.to_s}] #{command.node.name}\n"
          end
        end
      end
      return result
    end

    def print_state(plan)
      puts state(plan)
    end

    def node_select_options(c)
      c.desc 'Run plans for this nodes only'
      c.default_value ""
      c.arg_name 'node01.example.com,node02.example.com,/example\.com$/'
      c.flag [:nodes]

      c.desc 'Run plans for this roles only'
      c.default_value ""
      c.arg_name 'role01,role01,/^rolepattern/'
      c.flag [:roles]

      c.desc 'Exclude this nodes from the run'
      c.default_value ""
      c.arg_name 'node01.example.com,node02.example.com,/example\.com$/'
      c.flag [:exclude_nodes]

      c.desc 'Exclude this roles from the run'
      c.default_value ""
      c.arg_name 'role01,role01,/^rolepattern/'
      c.flag [:exclude_roles]

      c.desc 'Run plans for this nodes with this config only (You have to specify a JSON hash here)'
      c.default_value "{}"
      c.arg_name '\'{"var1": ["val1", "/val2/"], "var2": "val2"}\''
      c.flag [:nodes_by_config]

      c.desc 'Exclude nodes with this config from the run (You have to specify a JSON hash here)'
      c.default_value "{}"
      c.arg_name '\'{"var1": ["val1", "/val2/"], "var2": "val2"}\''
      c.flag [:exclude_nodes_by_config]

      c.desc 'Run plans for this nodes with this fact only (You have to specify a JSON hash here)'
      c.default_value "{}"
      c.arg_name '\'{"var1": ["val1", "/val2/"], "var2": "val2"}\''
      c.flag [:nodes_by_fact]

      c.desc 'Exclude nodes with this fact from the run (You have to specify a JSON hash here)'
      c.default_value "{}"
      c.arg_name '\'{"var1": ["val1", "/val2/"], "var2": "val2"}\''
      c.flag [:exclude_nodes_by_fact]
    end

    def run_options(c)
      node_select_options(c)

      c.desc 'Show only stuff the run would do but don\'t execute commands (verify commands will still be executed)'
      c.default_value false
      c.switch [:noop, :n]

      c.desc 'Select the step set to run (if nothing is specified it will try to run the step set "default")'
      c.default_value 'default'
      c.arg_name 'STEPSET'
      c.flag [:step_set, :s]
    end

    def parse_node_select_options(options)
      pattern_hash = {}
      [:nodes, :roles, :exclude_nodes, :exclude_roles].each do |key|
        hash = { key => options[key].split(',')}
        pattern_hash[key] = DopCommon::HashParser.pattern_list_valid?(hash, key) ?
          DopCommon::HashParser.parse_pattern_list(hash, key) : []
      end
      [:nodes_by_config, :exclude_nodes_by_config, :nodes_by_fact, :exclude_nodes_by_fact].each do |key|
        hash = {key => JSON.parse(options[key])}
        pattern_hash[key] = DopCommon::HashParser.hash_of_pattern_lists_valid?(hash, key) ?
          DopCommon::HashParser.parse_hash_of_pattern_lists(hash, key) : {}
      end
      # Select all nodes if nothing is included
      if [:nodes, :roles, :nodes_by_config, :nodes_by_fact].all?{|k| pattern_hash[k].empty?}
        pattern_hash[:nodes] = :all
      end
      OpenStruct.new(pattern_hash)
    rescue DopCommon::PlanParsingError => e
      raise StandardError, "Error while parsing the node selection options: #{e.message}"
    end

    def run_signal_handler(plan)
      plan.reset_signals
      signal_handler_thread = Thread.new do
        Dopi.log.info("Starting signal handling")
        signal_counter = 0
        Dopi::SignalHandler.new.handle_signals(:INT, :TERM) do
          signal_counter += 1
          case signal_counter
          when 1
            Dopi.log.warn("Signal received! The run will halt after all currently running commands are finished")
            plan.send_signal(:stop)
          when 2
            Dopi.log.error("Signal received! Sending termination signal to all the processes!")
            plan.send_signal(:abort)
          when 3
            Dopi.log.error("Signal received! Sending KILL signal to all the processes!")
            plan.send_signal(:kill)
          end
        end
      end
      signal_handler_thread.abort_on_exception = true
    end

    desc 'Validate a plan file'
    arg_name 'plan_file'
    command :validate do |c|
      c.action do |global_options,options,args|
        help_now!('Specify a plan file to add') if args.empty?
        help_now!('You can only add one plan') if args.length > 1
        if Dopi.plan_valid?(args[0])
          puts "Plan is valid"
        else
          exit_now!("Plan is NOT valid")
        end
      end
    end

    desc 'Add a new plan file to the plan cache'
    arg_name 'plan_file'
    command :add do |c|
      c.action do |global_options,options,args|
        help_now!('Specify a plan file to add') if args.empty?
        help_now!('You can only add one plan') if args.length > 1
        plan = Dopi.add_plan(args[0])
        puts plan.name
      end
    end

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

    desc 'Show the list of plans in the dopi plan cache'
    command :list do |c|
      c.action do |global_options,options,args|
        puts @plan_cache.list()
      end
    end

    desc 'Remove an existing plan from the plan cache'
    arg_name 'name'
    command :remove do |c|
      c.action do |global_options,options,args|
        help_now!('Specify a plan id to remove') if args.empty?
        help_now!('You can only remove one plan') if args.length > 1
        @plan_cache.remove(args[0])
      end
    end

    desc 'Show plan details and state'
    arg_name 'name'
    command :show do |c|
      c.desc 'Do not exit and continuously update the display'
      c.default_value false
      c.switch [:follow, :f]

      c.action do |global_options,options,args|
        help_now!('Specify a plan name to show') if args.empty?
        help_now!('You can only show one plan') if args.length > 1
        if options[:follow]
          begin
            Curses.noecho
            Curses.curs_set(0)
            Curses.init_screen
            plan = Dopi.load_plan(args[0])
            while true
              begin
                reload_plan = Dopi.load_plan(args[0])
                plan = reload_plan if reload_plan.kind_of?(Dopi::Plan)
              rescue
              end
              Curses.setpos(0, 0)
              Curses.addstr(state(plan))
              Curses.refresh
              sleep(1)
            end
          ensure
            Curses.close_screen
          end
        else
          print_state(Dopi.load_plan(args[0]))
        end
      end
    end

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

    desc 'Reset a failed plan'
    arg_name 'name'
    command :reset do |c|
      c.desc 'Force reset the states back to ready from every state'
      c.default_value false
      c.switch [:force, :f]

      c.action do |global_options,options,args|
        help_now!('Specify a plan name to run') if args.empty?
        help_now!('You can only run one plan') if args.length > 1
        plan = Dopi.load_plan(args[0])
        plan.state_reset_with_children(options[:force])
        Dopi.save_plan(plan)
        print_state(plan)
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
