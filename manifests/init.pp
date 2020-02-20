# @summary common configurations applied on Puppetmasters
#
# @example
#   include ::puppetmaster_common
#
class puppetmaster_common {

  # Automatically update the production environment every hour. 
  $r10k_deploy_script = '/usr/local/bin/r10k-deploy.sh'

  file { $r10k_deploy_script:
    ensure  => 'present',
    content => template('puppetmaster_common/r10k-deploy.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  cron { 'r10k-deploy':
    ensure  => 'present',
    command => $r10k_deploy_script,
    user    => 'root',
    hour    => '*',
    minute  => 50,
    require => File[$r10k_deploy_script],
  }

  # Remove old reports to prevent disk space from filling up
  cron { 'remove-old-reports':
    command => '/usr/bin/find /opt/puppetlabs/server/data/puppetserver/reports/ -type f -mtime +7 -delete',
    user    => 'root',
    hour    => 2,
    minute  => 0,
  }
}
