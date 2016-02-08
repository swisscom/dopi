module Dopi
  module Cli

    def self.node_select_options(command)
      command.desc 'Run plans for this nodes only'
      command.default_value ""
      command.arg_name 'node01.example.com,node02.example.com,/example\.com$/'
      command.flag [:nodes]

      command.desc 'Run plans for this roles only'
      command.default_value ""
      command.arg_name 'role01,role01,/^rolepattern/'
      command.flag [:roles]

      command.desc 'Exclude this nodes from the run'
      command.default_value ""
      command.arg_name 'node01.example.com,node02.example.com,/example\.com$/'
      command.flag [:exclude_nodes]

      command.desc 'Exclude this roles from the run'
      command.default_value ""
      command.arg_name 'role01,role01,/^rolepattern/'
      command.flag [:exclude_roles]

      command.desc 'Run plans for this nodes with this config only (You have to specify a JSON hash here)'
      command.default_value "{}"
      command.arg_name '\'{"var1": ["val1", "/val2/"], "var2": "val2"}\''
      command.flag [:nodes_by_config]

      command.desc 'Exclude nodes with this config from the run (You have to specify a JSON hash here)'
      command.default_value "{}"
      command.arg_name '\'{"var1": ["val1", "/val2/"], "var2": "val2"}\''
      command.flag [:exclude_nodes_by_config]
    end

    def self.parse_node_select_options(options)
      pattern_hash = {}
      [:nodes, :roles, :exclude_nodes, :exclude_roles].each do |key|
        hash = { key => options[key].split(',')}
        pattern_hash[key] = DopCommon::HashParser.pattern_list_valid?(hash, key) ?
          DopCommon::HashParser.parse_pattern_list(hash, key) : []
      end
      [:nodes_by_config, :exclude_nodes_by_config].each do |key|
        hash = {key => JSON.parse(options[key])}
        pattern_hash[key] = DopCommon::HashParser.hash_of_pattern_lists_valid?(hash, key) ?
          DopCommon::HashParser.parse_hash_of_pattern_lists(hash, key) : {}
      end
      # Select all nodes if nothing is included
      if [:nodes, :roles, :nodes_by_config].all?{|k| pattern_hash[k].empty?}
        pattern_hash[:nodes] = :all
      end
      OpenStruct.new(pattern_hash)
    rescue DopCommon::PlanParsingError => e
      raise StandardError, "Error while parsing the node selection options: #{e.message}"
    end

  end
end
