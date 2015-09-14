# DOPi Command Plugin: Custom SSH Command

This plugin executes custom commands on every node in the step over ssh.

By default the ssh custom command plugin will skip the host key checks. This
means you will be potentially vulnerable to man in the middle attacks. Since
DOPi is designed for the provisioning phase you are working with new nodes and
this will usually not be an issue, however changing keys because nodes get
new provisioned will be. To change this set **ssh_check_host_key** to true.

## credentials for login

The ssh/custom plugin and all the plugins that inherit from it can use
credentials from the credentials hash in the plan to login.

    credentials:
      'linux_staging_login':
        type: :username_password
        username: 'root'
        password: 'foo'

    steps:
      - name: 'set ssh login credentials'
        command:
          plugin: 'ssh/custom'
          credentials: 'linux_staging_login'
          exec: 'env'

You can also specify multiple credentials and the ssh plugin will try each one
of them in turn to login to the node.

    credentials:
      'linux_staging_login':
        type: :username_password
        username: 'root'
        password: 'foo'
      'linux_prod_login':
        type: :ssh_key
        private_key: '/home/root/.ssh/id_dsa'

    steps:
      - name: 'set ssh login credentials'
        command:
          plugin: 'ssh/custom'
          credentials:
            - 'linux_staging_login'
            - 'linux_prod_login'
          exec: 'env'

This can be set in each plugin (don't forget the validator plugins) or via
the set_plugin_defaults hash. The plugin defaults will be preserved for
subsequent steps until it is altered or deleted.

    credentials:
      'linux_staging_login':
        type: :username_password
        username: 'root'
        password: 'foo'
      'linux_prod_login':
        type: :ssh_key
        private_key: '/home/root/.ssh/id_dsa'

    steps:
      - name: 'set ssh login credentials'
        set_plugin_defaults:
          - plugins: '/^ssh/'
            :credentials:
              - 'linux_staging_login'
              - 'linux_prod_login'
        command:
          plugin: 'ssh/custom'
          exec: 'env'

The login via password will need the program sshpass to be installed on the
machine DOPi is running on. DOPi will display a warning if you specify a
username password credential but sshpass is not installed.

## ssh_root_pass auth (DEPRECATED >=0.4)

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

    - name "Say Hello World on a node"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'ssh/custom'
        exec: 'echo'
        arguments: "Hello World"

### Complete Example

    - name "Install an RPM on the node"
      nodes:
        - 'web01.example.com'
      command:
        plugin: 'ssh/custom'
        exec: 'yum'
        arguments: 'install -y puppet'
        expect_exit_codes: 0
        fail_on_warning: False
        parse_output:
          error:
            - '^No package puppet available'
