# @summary make r10k deploy the production branch every hour
#
class puppetmaster_common::r10k_deploy {

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
}
