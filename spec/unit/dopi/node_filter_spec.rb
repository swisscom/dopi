require 'spec_helper'

class NodeFilterTest
  include Dopi::NodeFilter
end

describe Dopi::NodeFilter do
  describe '#filter_nodes' do
    subject { NodeFilterTest.new.filter_nodes(nodes, filters) }

    context 'include only specified nodes' do
      let(:nodes) {[
        instance_double(Dopi::Node, :has_name? => true),
        instance_double(Dopi::Node, :has_name? => false)
      ]}
      let(:filters){OpenStruct.new({:nodes => '/foo/'})}

      it { is_expected.to include(nodes[0]) }
      it { is_expected.to_not include(nodes[1]) }
    end

    context 'exclude specified nodes' do
      let(:nodes) {[
        instance_double(Dopi::Node, :has_name? => true),
        instance_double(Dopi::Node, :has_name? => false)
      ]}
      let(:filters){OpenStruct.new({:nodes => :all, :exclude_nodes => '/foo/'})}

      it { is_expected.to include(nodes[1]) }
      it { is_expected.to_not include(nodes[0]) }
    end

    context 'include only specified roles' do
      let(:nodes) {[
        instance_double(Dopi::Node, :has_role? => true),
        instance_double(Dopi::Node, :has_role? => false)
      ]}
      let(:filters){OpenStruct.new({:roles => :all, :exclude_roles => '/foo/'})}

      it { is_expected.to include(nodes[1]) }
      it { is_expected.to_not include(nodes[0]) }
    end

    context 'exclude specified roles' do
      let(:nodes) {[
        instance_double(Dopi::Node, :has_role? => true),
        instance_double(Dopi::Node, :has_role? => false)
      ]}
      let(:filters){OpenStruct.new({:roles => '/foo/'})}

      it { is_expected.to include(nodes[0]) }
      it { is_expected.to_not include(nodes[1]) }
    end

    context 'include only specified nodes by config' do
      let(:nodes) {[
        instance_double(Dopi::Node, :config_includes? => true),
        instance_double(Dopi::Node, :config_includes? => false)
      ]}
      let(:filters){OpenStruct.new({:nodes_by_config => {'foo' => '/foo/'}})}

      it { is_expected.to include(nodes[0]) }
      it { is_expected.to_not include(nodes[1]) }
    end


  end
end


