# DOPi Command Plugin: Custom SSH Command

This plugin executes custom commands on every node in the step over ssh.

DOPi will connect to the node via ssh and execute the specified command.
It will use the configured ssh key **(ssh_key)** with the configured user
**(ssh_user)** unless **ssh_pass_auth** is set and a password for the node
is configured.

The login via password will need the program sshpass to be installed on the
machine DOPi is running on. The password can be specified as a global option
in the plan or be overwritten via hieradata.

    plan:
      ssh_root_pass: 'mypass'

    configuration:
      node:
        'web01.example.com':
           ssh_root_pass: 'myotherpass'

By default the ssh custom command plugin will skip the host key checks. This

means you will be potentially vulnerable to man in the middle attacks. Since
DOPi is designed for the provisioning phase you are working with new nodes and
this will usually not be an issue, however changing keys because nodes get
new provisioned will be. To change this set **ssh_check_host_key** to true.

## Plugin Settings:

The ssh custom command plugin is based on the [custom command plugin](doc/plugins/custom.md)
and inherits all its parameters.

### quiet (optional)

`default: true`

By default ssh will run in quiet mode and stuff like login banners will not
appear in the output. See the documentation about the "-q" flag in the ssh
man page for more information about this.

## Examples:

### Simple Example

    - name "My new Step"
      command:
        plugin: 'ssh/custom'
        exec: 'echo'
        arguments: "Hello World"

### Complete Example

    - name "My new Step"
      command:
        plugin: 'ssh/custom'
        exec: 'yum'
        arguments: 'install -y puppet'
        expect_exit_codes: 0
        fail_on_warning: False
        parse_output:
          error:
            - '^No package puppet available'
