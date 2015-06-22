
module CommandHelper

  def create_command(hash)
    node = instance_double('Dopi::Node', :name => 'test.example.com')
    step = instance_double('Dopi::Step', :name => 'Fake step for tests')
    command_parser = DopCommon::Command.new(hash)
    Dopi::Command.create_plugin_instance(command_parser, step, node)
  end

end
