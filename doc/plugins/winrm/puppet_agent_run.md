# DOPi Command Plugin: WinRM Puppet Agent run Command

This DOPi Plugin will run puppet on the nodes in the step.

## Plugin Settings:

The winrm/puppet_agent_run command plugin is based on the
[winrm custom command plugin](doc/plugins/winrm/powershell.md) and
inherits all it's parameters.

It will however overwrite the **exec** parameter, so it is not possible to
set a custom command in this plugin.

You may want to set a high **plugin_timeout** here to make sure it waits
long enough for all the nodes to come up if you provision the nodes while
waiting.

This plugin overwrites the defaults for the **expect_exit_codes** parameter.
Puppet will return an exit code of 2 if there where changes. Since this will
be what we are looking we have to expect this and mark it as success

`default overwrite for expect_exit_codes : [ 0, 2 ]`

If you are sure that there will be changes you should overwrite this with 2
to make sure there where changes. This may help you catching problems where
nodes don't actually get a configuration or are in the wrong environment.

The winrm/puppet_agent_run plugin has no additional parameters.

## Examples:

### Simple Example

    - name "Run puppet on a node"
      nodes:
        - 'web01.example.com'
      command: 'winrm/puppet_agent_run'

### Complete Example

    - name "Run puppet with parameters on a node"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'winrm/puppet_agent_run'
        plugin_timeout: 300
        arguments:
          '--server': 'puppetmaster.example.com'
          '--environment': 'development'
