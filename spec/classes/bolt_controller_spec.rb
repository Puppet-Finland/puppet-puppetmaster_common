# frozen_string_literal: true

require 'spec_helper'

describe 'puppetmaster_common::bolt_controller' do
  bionic = { supported_os:
            [{  'operatingsystem'        => 'Ubuntu',
                'operatingsystemrelease' => ['18.04'] }] }

  on_supported_os(bionic).each do |os, os_facts|
    context "on #{os}" do
      let(:params) do
        {  'puppetdb_url'               => 'https://puppet.example.org:8081',
           'inventory_template_content' => 'foobar',
           'ssh_private_key_content'    => 'foobar',
           'bolt_yaml_content'          => 'foobar' }
      end
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
