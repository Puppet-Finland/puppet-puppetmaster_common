#
# @summary migrate agent from Puppet 5 to Puppet 6
#
# @param targets
#   The node(s) to migrate to Puppet 6
#
# @param master_address
#   The FQDN of the Pupppet 6 master
#
# @param remove_puppet5
#   Whether to explicitly remove/move away most traces of Puppet 5
#   including the Puppet certificates
#
# @param ensure_puppet
#   Ensure that Puppet is running and enabled, or stopped and disabled
#
# @param puppet_environment
#   Puppet environment to define in the agent's config. Defaults to no
#   explicit environment (i.e. implicitly use "production")
#
plan puppetmaster_common::setup_puppet6_agent
(
  TargetSpec                $targets,
  String                    $master_address,
  Boolean                   $remove_puppet5 = true,
  Enum['running','stopped'] $ensure_puppet = 'running',
  Optional[String]          $puppet_environment = undef
)
{
  apply_prep($targets)

  if $remove_puppet5 {

    # Backup old certificates
    run_command('test -d /etc/puppetlabs/puppet/ssl && mv /etc/puppetlabs/puppet/ssl /etc/puppetlabs/puppet/ssl.bak || true', $targets)

    # Stop and remove Puppet 5 agent
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
  }

  # Install and configure Puppet 6 agent
  run_task('puppet_agent::install', $targets, '_run_as' => 'root', 'collection' => 'puppet6')

  apply($targets) {
    $ini_defaults = { 'ensure'  => 'present',
                      'path'    => '/etc/puppetlabs/puppet/puppet.conf',
                      'section' => 'agent' }

    ini_setting { 'server':
      setting => 'server',
      value   => $master_address,
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

  $puppet_output = run_command('/opt/puppetlabs/bin/puppet agent --onetime --verbose --show_diff --no-daemonize --color=false --waitforcert 10', $targets) # lint:ignore:140chars

  out::message($puppet_output)

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
