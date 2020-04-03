#
# @summary setup a Puppet Bolt controller node
#
# This class sets up a Boltdir in /etc/puppetlabs/bolt, configures a cronjob to
# create and update the PuppetDB inventory file based on an inventory template
# NS installs SSH keys for the root user Dor connecting to the target nodes.
# Contents of bolt.yaml and inventory template have to be passed in as
# parameters as they will be highly site-specific.
#
# Many of the parameters are now hardcoded (in local variables) to keep the
# code simple.
#
# @param puppetdb_url
#   PuppetDB URL
# @param inventory_template_content
#   Passed to the content parameter of the File resource that manages
#   the Puppet inventory template file
# @param ssh_private_key_content
#   The private key used to connect to target nodes
# @param bolt_yaml_content
#   Passed to the file resource that manages bolt.yaml
#
class puppetmaster_common::bolt_controller
(
  Stdlib::HTTPUrl $puppetdb_url,
  String          $inventory_template_content,
  String          $ssh_private_key_content,
  String          $bolt_yaml_content
)
{
  $bolt_dir = '/etc/puppetlabs/bolt'
  $bolt_ssh_private_key = '/root/.ssh/puppet-ssh_sudoers'
  $bolt_user = 'root'
  $inventory_path = "${bolt_dir}/inventory.yaml"
  $inventory_template_path = "${bolt_dir}/inventory-template.yaml"
  $ssh_sudoers_user = 'bolt'

  file { $bolt_dir:
    ensure => 'directory',
    owner  => $bolt_user,
    group  => $bolt_user,
    mode   => '0750',
  }

  file { $inventory_template_path:
    ensure  => 'present',
    content => $inventory_template_content,
    owner   => $bolt_user,
    group   => $bolt_user,
    mode    => '0640',
    require => File[$bolt_dir],
  }

  # Bolt needs to know it is in a project directory. This can
  # be accomplished by having bolt.yaml file in there.
  file { "${bolt_dir}/bolt.yaml":
    ensure  => 'present',
    content => $bolt_yaml_content,
    owner   => $bolt_user,
    group   => $bolt_user,
    mode    => '0640',
  }

  class { '::bolt::controller':
    user                    => 'root',
    puppetdb_url            => $puppetdb_url,
    inventory_path          => $inventory_path,
    inventory_template_path => $inventory_template_path,
  }

  class { '::ssh_sudoers::controller':
    user                    => 'root',
    ssh_private_key_content => $ssh_private_key_content,
  }
}
