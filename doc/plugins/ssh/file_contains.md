# DOPi Command Plugin: File Contains SSH Command

This DOPi Plugin will check if the specified file on the node contains a
specific pattern. This plugin is usually used as a verify command to check
if a command has to be executed on a node.

## Plugin Settings:

The ssh/file_contains command plugin is based on the
[ssh custom command plugin](doc/plugins/ssh/custom.md) and the
[custom command plugin](doc/plugins/custom.md) and inherits all their
parameters.

It will however overwrite the **exec** parameter, so it is not possible to
set a custom command in this plugin.

### file (required)

The file to check

### pattern (required)

The regular expression to check against

## Example:

    - name "Run puppet on a node"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'ssh/puppet_agent_run'
        verify_commands:
          - plugin: 'ssh/file_contains'
            file: '/etc/puppet/puppet.conf'
            pattern: 'puppetmaster.example.com'
        arguments:
          '--server': 'puppetmaster.example.com'
