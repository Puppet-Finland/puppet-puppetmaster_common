#
# @summary
#   Migrate agent from older to newer Puppetserver. The assumption is that
#   Puppet servers and agents are and will be running same Puppet version.
#
# @param targets
#   The node(s) to migrate to new Puppet master
#
# @param simulate
#   Do not make any changes, only show what would be done
#
# @param source_version
#   Version of Puppet to migrate away from. Used to remove release packages.
#
# @param target_version
#   Version of Puppet to migrate to. Used to download release packages.
#
# @param manage_host_entry
#   Whether to add manage the /etc/hosts entry for the new Puppet master
#
# @param master_hostname
#   The hostname of the new Puppet master. This will get added to /etc/hosts
#   with the value of master_address, but only if manage_host_entry is true.
#
# @param old_master_orchestration_address
#   The FQDN of the old Puppet 5 server. Used to optionally remove the node
#   from Puppet CA and PuppetDB.
#
# @param master_address
#   The IP address of the new Puppet master. This will get added to
#   /etc/hosts on the agents if manage_host_entry is true. Also used as the
#   default value of master_orchestration_address.
#
# @param master_orchestration_address
#   The IP address used by Bolt to connect to the new Puppet master. You would
#   use this when you reach out to new Puppet master via public IP while the
#   agents connect to its private ip.
#
# @param ensure_puppet
#   Ensure that Puppet is running and enabled, or stopped and disabled after
#   this process. Also sets --noop to the initial Puppet run with new Puppet master when
#   this is set to 'stopped'.
#
# @param puppet_environment
#   Puppet environment to define in the agent's config. Defaults to no
#   explicit environment (i.e. implicitly use "production")
#
plan puppetmaster_common::migrate_agent
(
  TargetSpec                $targets,
  Boolean                   $simulate = true,
  Integer[5,6]              $source_version = 5,
  Integer[6,7]              $target_version = 7,
  Boolean                   $manage_host_entry = false,
  Optional[Stdlib::Host]    $old_master_orchestration_address = undef,
  Stdlib::IP::Address       $master_address,
  String                    $master_hostname = 'puppet',
  Enum['running','stopped'] $ensure_puppet = 'running',
  Optional[String]          $master_orchestration_address = undef,
  Optional[String]          $puppet_environment = undef
)
{

  if $source_version >= $target_version {
    fail('Can only switch to a newer Puppet version!')
  }

  # These commands work for Puppet 5+
  $ca_list_cmd = '/opt/puppetlabs/bin/puppetserver ca list --certname'
  $ca_clean_cmd = '/opt/puppetlabs/bin/puppetserver ca clean --certname'
  $ca_sign_cmd = '/opt/puppetlabs/bin/puppetserver ca sign --certname'
  $puppetdb_node_deactivate_cmd = '/opt/puppetlabs/bin/puppet node deactivate'

  $_master_orchestration_address = $master_orchestration_address ? {
    undef   => $master_address,
    default => $master_orchestration_address,
  }

  if $ensure_puppet == 'running' {
    $noop = ''
    $enable_puppet = true
  } else {
    $noop = '--noop'
    $enable_puppet = false
  }

  # This step is required even in no-operation mode
  apply_prep($targets)

  # Setup Puppet agent on the target nodes
  if $simulate {
    out::message("Would setup Puppet ${target_version} on ${targets}")
  } else {
    out::message("Setting up Puppet ${target_version} on ${targets}")

    apply($targets) {
      service { 'puppet':
        ensure => 'stopped',
        enable => false,
      }

      package { ['puppet-agent', "puppet${source_version}-release"]:
        ensure  => 'absent',
        require => Service['puppet'],
      }
    }

    # Backup old certificates
    run_command('test -d /etc/puppetlabs/puppet/ssl && mv /etc/puppetlabs/puppet/ssl /etc/puppetlabs/puppet/ssl.bak || true', $targets)

    # Install new Puppet agent
    run_task('puppet_agent::install', $targets, '_run_as' => 'root', 'collection' => "puppet${target_version}")

    # Configure new Puppet agent
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

    # Issue a CSR on all new Puppet agents. We don't want to error out if a
    # certificate is not received, which is to be expected.
    run_command("/opt/puppetlabs/bin/puppet agent --onetime --verbose --show_diff --no-daemonize --color=false ${noop} || true", $targets) # lint:ignore:140chars
  }

  # Add node to new master and optionally remove it from the old
  get_targets($targets).each |$target| {
    $my_fqdn = $target.facts['fqdn']

    $target_ca_list_cmd_result = run_command("${ca_list_cmd} ${my_fqdn}", $_master_orchestration_address, { '_catch_errors' => true })
    $target_ca_list_cmd_exit_code = $target_ca_list_cmd_result.to_data[0]['value']['exit_code']

    if $target_ca_list_cmd_exit_code == 1 {
      if $simulate {
        out::message("Would add node ${my_fqdn} to ${master_orchestration_address}")
      } else {
        out::message("Adding node ${my_fqdn} to ${master_orchestration_address}")
        run_command("${ca_sign_cmd} ${my_fqdn}", $_master_orchestration_address)
      }
    }

    if $old_master_orchestration_address {
      $source_ca_list_cmd_result = run_command("${ca_list_cmd} ${my_fqdn}", $old_master_orchestration_address, { '_catch_errors' => true })
      $source_ca_list_cmd_exit_code = $source_ca_list_cmd_result.to_data[0]['value']['exit_code']

      if $source_ca_list_cmd_exit_code == 0 {
        if $simulate {
          out::message("Would remove node ${my_fqdn} from ${old_master_orchestration_address}")
        } else {
          out::message("Removing node ${my_fqdn} from ${old_master_orchestration_address}")
          # Remove node from old Puppet master's CA
          run_command("${ca_clean_cmd} ${my_fqdn}", $old_master_orchestration_address) # lint:ignore:140chars

          # Remove node from old Puppet master's PuppetDB
          run_command("${puppetdb_node_deactivate_cmd} ${my_fqdn}", $old_master_orchestration_address) # lint:ignore:140chars
        }
      }
    }
  }

  # Enable or disable Puppet agent on all targets
  apply($targets) {
    service { 'puppet':
      ensure => $ensure_puppet,
      enable => $enable_puppet,
    }
  }
}
