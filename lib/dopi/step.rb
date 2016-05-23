#
# Step
#
require 'parallel'

module Dopi
  class Step
    include Dopi::State
    include Dopi::NodeFilter

    DEFAULT_MAX_IN_FLIGHT = 3

    attr_accessor :plan

    def initialize(step_parser, plan)
      @step_parser = step_parser
      @plan        = plan
      @nodes       = filter_nodes(plan.nodes, step_parser)

      @next_mutex   = Mutex.new
      @notify_mutex = Mutex.new
      @queue        = Queue.new

      command_sets.each{|command_set| state_add_child(command_set)}
    end

    def name
      @step_parser.name
    end

    def valid?
      if @nodes.empty?
        Dopi.log.error("Step '#{name}': Nodes list is empty")
        return false
      end
      # since they are identical in respect to parsing
      # we only have to check one of them
      command_sets.first.valid?
    end

    def command_sets
      @command_sets ||= @nodes.map do |node|
        delete_plugin_defaults
        set_plugin_defaults
        Dopi::CommandSet.new(@step_parser, self, node)
      end
    end

    def run(run_options)
      if state_done?
        Dopi.log.info("Step '#{name}' is in state 'done'. Skipping")
        return
      end
      Dopi.log.info("Starting to run step '#{name}'")

      nodes_to_run = filter_nodes(@nodes, run_options[:run_for_nodes])
      command_sets_to_run = command_sets.select {|cs| nodes_to_run.include?(cs.node)}

      unless run_options[:noop]
        run_canary(run_options, command_sets_to_run) if canary_host
        run_command_sets(run_options, command_sets_to_run) unless state_failed?
      else
        command_sets_to_run.each{|command_set| command_set.run(run_options[:noop])}
      end

      Dopi.log.info("Step '#{name}' successfully finished.") if state_done?
      Dopi.log.error("Step '#{name}' failed! Stopping execution.") if state_failed?
    end

    private

    def run_canary(run_options, command_sets_to_run)
      pick = rand(command_sets_to_run.length - 1)
      command_sets_to_run[pick].run(run_options[:noop])
    end

    def run_command_sets(run_options, command_sets_to_run)
      in_threads = max_in_flight == -1 ? command_sets_to_run.length : max_in_flight
      pick = lambda { next_command_set(command_sets_to_run) || Parallel::Stop }
      Parallel.each(pick, :in_threads => in_threads) do |command_set|
        Dopi::ContextLoggers.log_context = command_set.node.name
        command_set.run(run_options[:noop])
        notify_done
      end
    end

    # notify the waiting thread that a command_set has finished it's run
    def notify_done
      @notify_mutex.synchronize do
        @queue.push(1)
      end
    end

    # This method returns the next command_set which is ready
    # to run. If no node is ready because of constrains
    # it will block the thread until notify_done was called
    # from a finishing thread. If no command_set is in the state
    # ready it will return nil.
    def next_command_set(command_sets_to_run)
      @next_mutex.synchronize do
        ready_command_sets = command_sets_to_run.select{|n| n.state == :ready}
        return nil if ready_command_sets.empty?
        loop do
          return nil if state_failed? or signals[:stop]
          @notify_mutex.synchronize do
            @queue.clear
            next_command_set = ready_command_sets.find{|cs| is_runnable?(cs.node)}
            unless next_command_set.nil?
              next_command_set.state_start
              return next_command_set
            end
          end
          @queue.pop # wait until a thread notifies it has finished
        end
      end
    end

    # check if a node is runnable or if there are constrains
    # which prevent it from running
    def is_runnable?(node)
      if max_per_role
        running_groups[node.role] < max_per_role
      else
        true
      end
    end

    # return a hash with the group names as keys and the
    # amount of running nodes as value
    def running_groups
      role_counter = Hash.new(0)
      command_sets.each do |command_set|
        if [:running, :starting].include? command_set.state
          role_counter[command_set.node.role] += 1
        end
      end
      role_counter
    end

    def max_in_flight
      @max_in_flight ||= @step_parser.max_in_flight || @plan.max_in_flight || DEFAULT_MAX_IN_FLIGHT
    end

    def max_per_role
      @max_per_role ||= @step_parser.max_per_role || nil
    end

    def canary_host
      @canary_host ||= @step_parser.canary_host || @plan.canary_host
    end

    def delete_plugin_defaults
      if @step_parser.delete_plugin_defaults == :all
        # Wipe all the defaults
        PluginManager.plugin_klass_list('^dopi/command/').each do |plugin_klass|
          @nodes.each{|node| plugin_klass.delete_plugin_defaults(node.name)}
        end
      else
        @step_parser.delete_plugin_defaults.each do |entry|
          plugin_list(entry[:plugins]).each do |plugin_klass|
            if entry[:delete_keys] == :all
              @nodes.each{|node| plugin_klass.delete_plugin_defaults(node.name)}
            else
              entry[:delete_keys].each do |key|
                @nodes.each{|node| plugin_klass.delete_plugin_default(node.name, key)}
              end
            end
          end
        end
      end
    end

    def set_plugin_defaults
      @step_parser.set_plugin_defaults.each do |entry|
        defaults_hash = entry.dup
        defaults_hash.delete(:plugins)
        plugin_list(entry[:plugins]).each do |plugin_klass|
          @nodes.each{|node| plugin_klass.set_plugin_defaults(node.name, defaults_hash)}
        end
      end
    end

    def plugin_list(plugin_filter_list)
      if plugin_filter_list == :all
        PluginManager.plugin_klass_list('^dopi/command/')
      else
        all_plugin_names = PluginManager.plugin_name_list('^dopi/command/').map{|p| p.sub('dopi/command/', '')}
        selected_plugin_names = plugin_filter_list.map do |filter|
          case filter
          when Regexp then all_plugin_names.select{|p| p =~ filter}
          else all_plugin_names.select{|p| p == filter}
          end
        end
        selected_plugin_names.flatten.uniq.map{|p| PluginManager.plugin_klass('dopi/command/' + p)}
      end
    end

  end
end
