# Dopi

DOPi is the "inner" part of the Deployment Orchestrater for Puppet (DOP).
It is the part that connects into your nodes and runs commands in a defined
order.

The main purpose of DOPi is to get your nodes into a state where they can
run Puppet or any other config management. It will also allows you to
orchestrate this Puppet runs so you can setup your nodes in the desired order.

DOPi orchestrates puppet runs, mco calls and custom commands over different nodes

DOPi uses a DOP plan file to find out what it has to run in what order on
which nodes. To learn more about the syntax of this DOP plan file make sure
you checkout the Documentation in [dop_common](https://gitlab.swisscloud.io/clu-dop/dop_common/blob/master/README.md).

If you are new to DOPi make sure you check out the [getting started guide](doc/getting_started.md).

## Change Log

Dopi is currently under heavy development and should not be considered stable. If you are
upgrading make sure you carefully ready the [Change Log](CHANGELOG.md)

## DOPi as a library

### Install 

Add this line to your application's Gemfile:

    gem 'dopi'

And then execute:

    $ bundle

### Usage Example

    require 'dopi'

    Dopi.configure do |config|
      config.role_variable = 'my_role'
      config.role_default  = 'base'
    end

    plan_parser = DopCommon::Plan.new(YAML.load_file(plan_file))
    plan = Dopi::Plan.new(plan_parser)
    plan.run

    puts "Plan status: #{plan.state.to_s}"
    plan.steps.each do |step|
      puts "[#{step.state.to_s}] #{step.name}"
      step.commands.each do |command|
        puts "  [#{command.state.to_s}] #{command.node.fqdn}"
      end
    end

#### With DOP plan cache

This will persist the plan in the DOP plan cache.

    require 'dopi'

    Dopi.configure do |config|
      config.role_variable = 'my_role'
      config.role_default  = 'base'
    end

    plan = Dopi.add_plan(plan_file)
    Dopi.run_plan(plan)

    puts "Plan status: #{plan.state.to_s}"
    plan.steps.each do |step|
      puts "[#{step.state.to_s}] #{step.name}"
      step.commands.each do |command|
        puts "  [#{command.state.to_s}] #{command.node.fqdn}"
      end
    end
    
### DOPi as a CLI

### Install

Install the gem

    $ gem install dopi

Help on all available options

    $ dopi help

### Usage Example

First you have to add a plan to the plan cache:

    $ dopi add spec/data/plan/example_deploment_plan_test.yaml 
    example_deploment_plan_test 

This will return the plan name which can be used to run other
commands on that plan. You can get a list of all the plans in the
cache by running:

    $ dopi list
    example_deploment_plan_test

You can get information about the state of a plan with the show command
and the name of the plan:

    $ dopi show example_deploment_plan_test
    [ready] test_run
      [ready] mysql01.example.com
      [ready] web01.example.com
      [ready] web02.example.com
      [ready] haproxy01.example.com
      [ready] haproxy02.example.com
    [ready] Make sure we can login to all nodes
      [ready] mysql01.example.com
      [ready] web01.example.com
      [ready] web02.example.com
      [ready] haproxy01.example.com
      [ready] haproxy02.example.com
    [ready] ssh_test_run
      [ready] mysql01.example.com
    [ready] run_puppet
      [ready] mysql01.example.com
      [ready] web01.example.com
      [ready] web02.example.com
      [ready] haproxy01.example.com
      [ready] haproxy02.example.com
    [ready] run_puppet2
      [ready] mysql01.example.com
      [ready] web01.example.com
      [ready] web02.example.com
      [ready] haproxy01.example.com
      [ready] haproxy02.example.com

You can run the plan with the run command and the name:

    $ dopi run example_deploment_plan_test


## Plan File Format

For a general description of the DOP plan file format, please see the
[dop_common](https://gitlab.swisscloud.io/clu-dop/dop_common/blob/master/README.md)
documentation. The documentation in this gem will focus on the command hashes for all
the basic plugins which are shipped with DOPi and on how to create your own custom plugins.

### How to use Plugins

DOPi uses plugins to run commands on the nodes. Each step in the plan has one
command and as many verify_commands as needed. DOPi will run all the verify_commands
before the command and will run the command only if one of them fails.

In general a plugin is specified like this:

```YAML
    - name "My new Step"
      nodes: 'all'
      command:
        plugin: 'my_plugin_name'
        parameter1: 'foo'
        parameter2: 'bar'
```

Some of the Plugins don't actually need parameters, so they can be called with the short form:

```YAML
    - name "My new Step"
      nodes: 'all'
      command: 'my_simple_plugin'
```

### Verify Commands

It is usually a good idea to check if a step is required to run. This way you can make your
plans idempotent. You can define any number of verify commands. If they all are successful
DOPi will skip the run. There are a hand full of plugins who are written exactly for this
purpose.

```YAML
    - name "Create file if it does not exist"
      command:
        verify_commands:
          - plugin; 'ssh/file_exists'
            file: '/tmp/somefile'
        plugin: 'ssh/custom'
        exec: 'echo'
        arguments: "'Hello World' > /tmp/somefile"
```

### Generic Plugin Parameters

There are some generic parameters every plugin supports:

#### plugin_timeout (optional)

`default: 300`

The time in seconds after which DOPi will kill the thread and mark the step as failed.

#### verify_after_run (optional)

`default: false`

The verify commands will be executed again after the command run and the step will
only succeed if the verify commands all successful.

### Command Execution Plugins

This are the plugins generally used in steps as commands

[custom](doc/plugins/custom.md)

[ssh/custom](doc/plugins/ssh/custom.md)

[ssh/wait_for_login](doc/plugins/ssh/wait_for_login.md)

[ssh/reboot](doc/plugins/ssh/reboot.md)

[ssh/puppet_agent_run](doc/plugins/ssh/puppet_agent_run.md)

[ssh/file_replace](doc/plugins/ssh/file_replace.md)

[ssh/file_deploy](doc/plugins/ssh/file_deploy.md)

[mco/rpc](doc/plugins/mco/rpc.md)

[winrm/cmd](doc/plugins/winrm/cmd.md)

[winrm/powershell](doc/plugins/winrm/powershell.md)

[winrm/wait_for_login](doc/plugins/winrm/wait_for_login.md)

[winrm/reboot](doc/plugins/winrm/reboot.md)

### Verification Plugins

This are some helper plugins that check stuff on the nodes. They are
usefull for verify_commands. However, every normal plugin can be used
as a verify_command and vice versa.

[ssh/file_contains](doc/plugins/ssh/file_contains.md)

[ssh/file_exists](doc/plugins/ssh/file_exists.md)

[winrm/file_contains](doc/plugins/winrm/file_contains.md)

[winrm/file_exists](doc/plugins/winrm/file_exists.md)

## Example Plans

There are some examples for DOPi in the sources which are also used for tests

[DOPi test environment setup](spec/integration/dopi/build_dop_test_environment.yaml)

More can be found in the plans directory.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Run the test suit

Most of the tests depend on Vagrant to create an actual test environment where the DOPi
plugins can be tested under real conditions.

To setup the test suit you need a working vagrant (https://www.vagrantup.com/) installation
with the dop_common gem added as a plugin:

    cd /tmp
    git clone https://gitlab.swisscloud.io/clu-dop/dop_common.git
    cd dop_common
    gem build dop_common.gemspec
    vagrant plugin install ./dop_common-*.gem

After you install the plugin you have to setup the test machines with the rake task:

    cd /path/to/dopi/
    bundle install --path .bundle
    bundle exec rake spec:prep

You should always rerun 'spec:prep' to make sure your test environment is started
and setup correctly.

The tests will connect to the machines and for now you require some hosts file entries
to work correctly. Add the following lines to your /etc/hosts:

    # Host entries for DOPi test environment
    192.168.56.101 puppetmaster.example.com
    192.168.56.102 broker.example.com
    192.168.56.103 linux01.example.com
    192.168.56.104 linux02.example.com
    192.168.56.105 linux03.example.com
    192.168.56.106 windows01.example.com

Now you are ready to run the test suit:

    bundle exec rake

If you reboot your machine or stop the test machines you can make sure the test
environment is ready and built by simply running the setup again:

    bundle exec rake testenv:setup
