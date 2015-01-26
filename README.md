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

Run a deployment plan

    $ dopi deployment_plan.yaml

Help on all available options

    $ dopi --help

### Usage Example

TODO: Write CLI example after CLI rewrite

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

