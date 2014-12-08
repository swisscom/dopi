#
# Step
#
 
module Dopi
  class Step

    attr_reader :name, :nodes, :commands, :state


    def initialize(step_config_hash, all_nodes)
      @name = step_config_hash['name']
      @commands = []
      @threads = []
      @state = :ready

      # assemble a list of the nodes assigned to the step
      @nodes = []
      unless step_config_hash['nodes'].nil?
        @nodes += get_nodes_from_nodes_list(step_config_hash['nodes'], all_nodes)
      else  
        Dopi.log.debug("No nodes field found for step #{@name}")
      end
      unless step_config_hash['roles'].nil?
        @nodes += get_nodes_from_roles_list(step_config_hash['roles'], all_nodes)
      else
        Dopi.log.debug("No roles field found for step #{@name}")
      end
      @nodes.uniq!

      # extract the plugin name from the step hash
      plugin_name = nil
      if step_config_hash['command']
        if step_config_hash['command'].class == String
          plugin_name = command_hash
        elsif step_config_hash['command']['name'].class == String
          plugin_name = step_config_hash['command']['name']
        else
          raise "command part of step #{name} is invalid"
        end
      else
        raise "No command found for step #{name}"
      end
      
      # create instances from command plugin
      @nodes.each do |node|
        @commands << Dopi::Command.create_plugin_instance(plugin_name, node, step_config_hash['command'])
      end
    end


    def get_nodes_from_nodes_list(nodes_list, all_nodes)
      nodes = []
      # Match keywords (corrently there is only "all")
      if nodes_list.class == String
        
        if nodes_list.casecmp('all') == 0
          Dopi.log.debug("Adding all nodes to the step #{@name}")
          nodes = all_nodes
        else
          raise "Unknown keyword #{nodes_list} for nodes field in step #{@name}"
        end
      # Assemble node list from the nodes array
      elsif nodes_list.class == Array
        nodes_list.each do |node_fqdn|
          selected_nodes = all_nodes.select {|n| n.fqdn == node_fqdn}
          raise "node #{node_fqdn} is not defined" if selected_nodes == []
          Dopi.log.debug("Adding node to the step #{@name}")
          Dopi.log.debug(selected_nodes.inspect)
          nodes += selected_nodes
        end
      else
        raise "nodes field in step #{step['name']} is not an array or keyword"
      end
      return nodes
    end


    def get_nodes_from_roles_list(roles_list, all_nodes)
      nodes = []
      if roles_list.class == Array
        roles_list.each do |node_role|
          selected_nodes = all_nodes.select {|n| n.role == node_role}
          Dopi.log.debug("Adding nodes with role #{node_role} to the step #{@name}")
          Dopi.log.debug(selected_nodes.inspect)
          nodes += selected_nodes
        end
      else
        raise "roles field in step #{step['name']} is not an array"
      end
      return nodes
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
      until threads_running > 0 do
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
