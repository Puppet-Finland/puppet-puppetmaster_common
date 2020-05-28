# @summary make r10k deploy the production branch every hour
#
class puppetmaster_common::r10k_deploy
(
  Boolean $autodeploy = true,
  Variant[Array[String], Array[Integer[0-23]], String, Integer[0-23]] $hour = '*',
  Variant[Array[String], Array[Integer[0-59]], String, Integer[0-59]] $minute = '50',
  Variant[Array[String], Array[Integer[0-7]],  String, Integer[0-7]]  $weekday = '*',
)
{

  # Automatically update the production environment every hour.
  $r10k_deploy_script = '/usr/local/bin/r10k-deploy.sh'

  file { $r10k_deploy_script:
    ensure  => 'present',
    content => template('puppetmaster_common/r10k-deploy.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  $cron_ensure = $autodeploy ? {
    true    => 'present',
    default => 'absent',
  }

  cron { 'r10k-deploy':
    ensure  => $cron_ensure,
    command => $r10k_deploy_script,
    user    => 'root',
    hour    => $hour,
    minute  => $minute,
    weekday => $weekday,
    require => File[$r10k_deploy_script],
  }
}
