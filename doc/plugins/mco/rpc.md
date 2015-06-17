# DOPi Command Plugin: MCollective RPC Command

This DOPi Plugin will trigger an action of a MCollective agent on the
nodes in the Step. The plugin can call any agent and any action and will
mark the step as failed according to the status in the reply.

However, do to the generic nature of this plugin it will not be able to
parse the data structure returned by the agent as this is agent specific.
Dopi will warn about this when am agent is called with this plugin because
some errors that are not reflected in the status code may not be caught
by this plugin.

## Plugin Settings:

### agent (required)

The MCollective agent to be called. This agent has to be installed on
the nodes and the machine DOPi is running on. The DOPi validator will
check if the agent is present on the machine where you try to run the
plan.

### action (required)

The action we call on the specified agent. Consult the documentation of
the MCollective agent in question for a list of valid actions. The DOPi
validator will check if the agent supports such an action and fail if it
doesn't.

### options (optional)

`default: {}`

The options hash passed to the MCollective client. Check the output of
"mco help rpc" to get a list of valid options. However not all of this options
will make sense in this context. For example, you should never specify a filter
because DOPi already takes care of that via the node list of the step.

### arguments (optional)

`default: {}`

The arguments passed to the MCollective agent. Check the agent documentation to
get a list of required and optional arguments. DOPi will use the validation methods
provided by MCollective agents and fail the plan validation if the arguments are not
correct or the values are not valid.

### expect_exit_codes (optional)

`default: 0`

The exit codes DOPi should expect in the status code returned by the MCollective
agent. It the status code is an exit code not listed here, DOPi will mark the run
as failed. The values can be a number, an array of numbers or :all for all possible exit
codes. Will replace the current default.


## Examples:

### Simple Example

    - name "Get the inventory of a node"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'mco/rpc'
        agent: 'rpcutil'
        action: 'inventory'

### Complete Example

    - name "Get a fact of a node"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'mco/rpc'
        agent: 'rpcutil'
        action: 'get_fact'
        arguments:
          :fact: 'osfamily'
        options:
          :timeout: 30
          :ttl: 60
