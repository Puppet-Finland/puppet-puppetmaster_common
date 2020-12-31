#
# @summary migrate agent from Puppet 5 to Puppet 6
#
# @param targets
#   The node(s) to migrate to Puppet 6
#
# @param manage_host_entry
#   Whether to add manage the /etc/hosts entry for the Puppet 6 master
#
# @param master_hostname
#   The hostname of the  Puppet 6 master. This will get added to /etc/hosts
#   with the value of master_address, but only if manage_host_entry is true.
#
# @param old_master_orchestration_address
#   The FQDN of the old Puppet 5 server. Used to optionally remove the node
#   from Puppet CA and PuppetDB.
#
# @param master_address
#   The FQDN or IP address of the Puppet 6 master. This will get added to
#   puppet.conf on the agents
#
# @param master_orchestration_address
#   The IP address used by Bolt to connect to the Puppet 6 master. You would
#   use this when you reach out to Puppet 6 master via public IP while the
#   agents connect to its private ip.
#
# @param ensure_puppet
#   Ensure that Puppet is running and enabled, or stopped and disabled after
#   this process.
#
# @param puppet_environment
#   Puppet environment to define in the agent's config. Defaults to no
#   explicit environment (i.e. implicitly use "production")
#
plan puppetmaster_common::setup_puppet6_agent
(
  TargetSpec                $targets,
  Boolean                   $manage_host_entry = false,
  Optional[String]          $old_master_orchestration_address = undef,
  String                    $master_address,
  String                    $master_hostname = 'puppet',
  Enum['running','stopped'] $ensure_puppet = 'running',
  Optional[String]          $master_orchestration_address = undef,
  Optional[String]          $puppet_environment = undef
)
{
  $_master_orchestration_address = $master_orchestration_address ? {
    undef   => $master_address,
    default => $master_orchestration_address,
  }

  apply_prep($targets)

  # Stop Puppet Agent
  apply($targets) {
    service { 'puppet':
      ensure => 'stopped',
      enable => false,
    }

    package { ['puppet-agent', 'puppet5-release']:
      ensure  => 'absent',
      require => Service['puppet'],
    }
  }

  # Backup old certificates
  run_command('test -d /etc/puppetlabs/puppet/ssl && mv /etc/puppetlabs/puppet/ssl /etc/puppetlabs/puppet/ssl.bak || true', $targets)

  # Install Puppet 6 agent
  run_task('puppet_agent::install', $targets, '_run_as' => 'root', 'collection' => 'puppet6')

  # Configure Puppet 6 agent
  apply($targets) {
    if $manage_host_entry {
      host { $master_hostname:
        ensure => 'present',
        ip     => $master_address,
      }
    }

    $ini_defaults = { 'ensure'  => 'present',
                      'path'    => '/etc/puppetlabs/puppet/puppet.conf',
                      'section' => 'agent' }

    ini_setting { 'server':
      setting => 'server',
      value   => $master_hostname,
      *       => $ini_defaults,
    }

    if $puppet_environment {
      ini_setting { 'environment':
        setting => 'environment',
        value   => $puppet_environment,
        *       => $ini_defaults,
      }
    }
  }

  # Issue a CSR on all Puppet 6 agents. We don't want to error out if a certificate
  # is not received, which is to be expected.
  run_command('/opt/puppetlabs/bin/puppet agent --onetime --verbose --show_diff --no-daemonize --color=false || true', $targets) # lint:ignore:140chars

  # Do what it takes on the old and new Puppet masters
  get_targets($targets).each |$target| {
    $my_fqdn = $target.facts['fqdn']

    # Sign all CSRs on Puppet 6 master
    run_command("/opt/puppetlabs/bin/puppetserver ca sign --certname ${my_fqdn}", $_master_orchestration_address)

    if $old_master_orchestration_address {
      # Remove node from Puppet 5 master's CA
      run_command("/opt/puppetlabs/bin/puppet node clean ${my_fqdn}", $old_master_orchestration_address) # lint:ignore:140chars

      # Remove node from Puppet 5 master's PuppetDB
      run_command("/opt/puppetlabs/bin/puppet node deactivate ${my_fqdn}", $old_master_orchestration_address) # lint:ignore:140chars
    }
  }

  # Enable or disable Puppet agent on all targets
  apply($targets) {
    $enable_puppet = $ensure_puppet ? {
      'running' => true,
      'stopped' => false,
    }

    service { 'puppet':
      ensure => $ensure_puppet,
      enable => $enable_puppet,
    }
  }
}
