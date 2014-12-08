# Dopi

DOPi orchestrates puppet runs, mco calls and custom commands over different nodes

## Installation

Add this line to your application's Gemfile:

    gem 'dopi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dopi

## Usage

Run a deployment plan

    $ dopi deployment_plan.yaml

Help on all available options

    $ dopi --help

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO until first release

### General
- [ ] Write unit tests
- [ ] Check how the logger initialization is done right in the CLI and GEM context
- [ ] Implement a proper state tracker to enable resume functionality

Command stuff:
- [x] Commands as plugins
- [ ] Load plugins from external paths
- [x] Custom command easier rewritable, facter code out into more methods
- [ ] implement "dop check"
- [ ] implement "node check"
- [x] implement "expect exit code"
- [x] SSH custom command
- [x] SSH puppet command

Plan:
- [ ] Create hiera example structure and test Hiera stuff

Steps:
- [x] Implement "max in flight" and parallel execution
- [ ] Fail step during run if a single node fails

CLI:
- [ ] Config file
- [ ] Rewrite with proper documentation if configuration is more or less clear
