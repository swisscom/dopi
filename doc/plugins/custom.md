# DOPi Command Plugin: Custom Command

This plugin executes custom commands on the the machine DOPi is running on.

DOPi will execute a customized command on the node DOPi is running on.
It will run the command once per node in the step and export the node
fqdn in the environment variable DOP_NODE_FQDN

## Plugin Settings:

### exec (required)

The command the plugin should execute for every node.

### arguments (optional)

`default: ""`

The arguments for the command. This can be set by a string as an array or
as a hash. All the elements of the hash and the array will be flattened
and joined with a space.

### env (optional)

`default: { DOP_NODE_FQDN => fqdn_of_node }`

The environment variables that should be set. Will be merged with the defalut hash

### expect_exit_codes (optional)

`default: 0`

The exit codes DOPi should expect if the program terminates. It the program
exits with an exit code not listed here, DOPi will mark the run as failed.
The values can be a number, an array of numbers or :all for all possible exit
codes. Will replace the current default.

### parse_output (optional)

`default: {}`

Here you can define patterns that match against the output of the command plugin
and flag certain lines as errors or warnings. The parse_output key should contain
a hash with two keys, 'error' and 'warning' which each can contain an array of
patterns.

### fail_on_warning

`default: false`

Set this to true if you want to threat warnings in the output as errors. This is
useful if the plugin already specifies the parsing patterns but your need to stop
the run on warnings.

## Examples:

### Simple Example

```YAML
    - name "Say Hello World on the machine DOPi is running on"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'custom'
        exec: 'echo'
        arguments: "Hello World from ${DOP_NODE_FQDN}"
```

### Complete Example

```YAML
    - name "Install an RPM on the machine DOPi is running on"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'custom'
        exec: 'yum'
        arguments: 'install -y puppet'
        expect_exit_codes: 0
        fail_on_warning: False
        parse_output:
          error:
            - '^No package puppet available'
            - 'Some other Error pattern'
          warning:
            - '^Warning:'
```

