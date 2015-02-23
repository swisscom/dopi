# Dopi

DOPi orchestrates puppet runs, mco calls and custom commands over different nodes

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

    plan = Dopi::Plan.new( File.read( my_new_plan.yaml ) )
    plan.run

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
    3addf8efff12351fa87c901cfacfe1f8edeb9557589b3bde544630dcb7eedc49 

This will return a plan identifier which can be used to run other
commands on that plan. You can get a list of all the plans in the
cache by running:

    $ dopi list
    3addf8efff12351fa87c901cfacfe1f8edeb9557589b3bde544630dcb7eedc49

You can get information about the state of a plan with the show command
and the id of the plan:

    $ dopi show 3addf8efff12351fa87c901cfacfe1f8edeb9557589b3bde544630dcb7eedc49
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

You can run the plan with the run command and the id:

    $ dopi run 3addf8efff12351fa87c901cfacfe1f8edeb9557589b3bde544630dcb7eedc49


## Plan File Format

For a general description of the DOP plan file format, please see the dop_common documentation. 
The documentation in this gem will focus on the command hashes for all the basic plugins which
are shipped with DOPi and on how to create your own custom plugins.

TODO: Write plugin documentation after plugin rewrite

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

