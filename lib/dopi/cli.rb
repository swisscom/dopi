#
# Dopi cli
#
require 'dopi'
require 'thor'

class Dopi::Cli < Thor
  desc "hello NAME", "say hello to NAME"
  def hello(name)
    puts "Hello #{name}"
  end
end
