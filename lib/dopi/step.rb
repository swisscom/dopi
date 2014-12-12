#
# Step
#
 
module Dopi
  class Step
    include Dopi::State

    attr_reader :name, :nodes

    def initialize(name, command_hash, nodes = [])
      @name = name
      @command_hash = command_hash
      @nodes = nodes
      @threads = []

      commands.each{|command| state_add_child(command)}
      raise "nodes list for step #{name} is empty" if @nodes.empty?
    end


    def plugin_name
      @plugin_name ||= case @command_hash
        when String then @command_hash
        when Hash then case @command_hash['plugin']
          when String then @command_hash['plugin']
          else raise "No plugin name found in command hash for step #{@name}"
        end
        else raise "Command is not a plugin name or a valid command hash in step #{@name}"
      end
    end


    def commands
      @commands ||= @nodes.map do |node|
        command_hash = @command_hash.class == Hash ? @command_hash : {}
        Dopi::Command.create_plugin_instance(plugin_name, node, command_hash)
      end
    end


    def threads_running
      @threads.count {|thread| thread.status}
    end


    def run(max_in_flight)
      state_run
      commands.each do |command|
        while threads_running >= max_in_flight do
          sleep(0.1)
        end
        break if state_failed?
        @threads << Thread.new { command.run }
      end
      # wait until all the threads have terminated
      while threads_running > 0 do
        sleep(0.1)
      end
    end

  end
end
