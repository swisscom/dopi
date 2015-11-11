# Dopi

DOPi orchestrates puppet runs, mco calls and custom commands over different nodes

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

For a general description of the DOP plan file format, please see the dop_common documentation. 
The documentation in this gem will focus on the command hashes for all the basic plugins which
are shipped with DOPi and on how to create your own custom plugins.

### How to use Plugins

DOPi uses plugins to run commands on the nodes. Each step in the plan has one
command and as many verify_commands as needed. DOPi will run all the verify_commands
before the command and will run the command only if one of them fails.

In general a plugin is specified like this:

```yaml
    - name "My new Step"
      command:
        plugin: my_plugin_name
        parameter1: foo
        parameter2: bar
```

Some of the Plugins don't actually need parameters, so they can be called with the short form:

```yaml
    - name "My new Step"
      command: my_simple_plugin
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

[ssh/puppet_agent_run](doc/plugins/ssh/puppet_agent_run.md)

[ssh/file_replace](doc/plugins/ssh/file_replace.md)

[mco/rpc](doc/plugins/mco/rpc.md)

[winrm/cmd](doc/plugins/winrm/cmd.md)

[winrm/powershell](doc/plugins/winrm/powershell.md)

[winrm/wait_for_login](doc/plugins/winrm/wait_for_login.md)

### Verification Plugins

This are some helper plugins that check stuff on the nodes. They are
usefull for verify_commands. However, every normal plugin can be used
as a verify_command and vice versa.

[ssh/file_contains](doc/plugins/ssh/file_contains.md)

[ssh/file_exists](doc/plugins/ssh/file_exists.md)

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

