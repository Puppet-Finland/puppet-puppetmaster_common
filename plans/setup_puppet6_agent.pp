#
plan puppetmaster_common::setup_puppet6_agent
(
  TargetSpec $targets,
  String     $master_address,
  Boolean    $remove_puppet5 = true
)
{
  apply_prep($targets)

  if $remove_puppet5 {

    # Backup old certificates
    run_command('test -d /etc/puppetlabs/puppet/ssl && mv /etc/puppetlabs/puppet/ssl /etc/puppetlabs/puppet/ssl.bak || true', $targets)

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
    ini_setting {
      default:
        ensure  => 'present',
        path    => '/etc/puppetlabs/puppet/puppet.conf',
        section => 'agent',
      ;
      ['server']:
        setting => 'server',
        value   => $master_address,
      ;
    }
  }

  $puppet_output = run_command("/opt/puppetlabs/bin/puppet agent --onetime --verbose --show_diff --no-daemonize --color=false --waitforcert 10", $targets)

  out::message($puppet_output)

  apply($targets) {
    service { 'puppet':
      enable => true,
      ensure => 'running',
    }
  }
}
