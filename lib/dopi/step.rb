#
# Step
#
 
module Dopi
  class Step

    attr_reader :name, :nodes, :state


    def initialize(name, command_hash, nodes = [])
      @name = name
      @command_hash = command_hash
      @nodes = nodes
      @threads = []
      @state = :ready

      raise "nodes list for step #{name} is empty" if @nodes.empty?
    end


    def plugin_name
      @plugin_name ||= case @command_hash
        when String then @command_hash
        when Hash then case @command_hash['plugin']
          when String then @commmand_hash['plugin']
          else raise "No plugin name found in command hash for step #{@name}"
        end
        else raise "Command is not a plugin name or a valid command hash in step #{@name}"
      end
    end


    def commands
      @commands ||= @nodes.map do |node|
        command_hash = @command_hash.class == Hash ? @command_hash : {}
        Dopi::Command.create_plugin_instance(plugin_name, @nodes, command_hash)
      end
    end


    def threads_running
      count = 0
      @threads.each do |thread|
        count += 1 if thread.status
      end
      Dopi.log.debug("Currently running threads: #{count}")
      count
    end


    def run(max_in_flight)
      @state = :in_progress
      # create and run the command threads
      @commands.each do |command|
        # wait with thread creation until we have less
        # than configured in flight
        while threads_running >= max_in_flight do
          sleep(0.1)
        end
        @threads << Thread.new { command.run }
      end
      # wait until all the threads have terminated
      while threads_running > 0 do
        sleep(0.1)
      end
      # create the step state from the command stated
      @commands.each do |command|
        @state = :failed if command.state == :failed
      end
      @state = :done unless @state == :failed 
    end


  end
end
