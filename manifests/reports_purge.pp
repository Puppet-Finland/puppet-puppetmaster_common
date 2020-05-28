# @summary clean up old yaml reports
#
class puppetmaster_common::reports_purge
(
  Integer $max_days = 7
)
{

  # Remove old reports to prevent disk space from filling up
  cron { 'remove-old-reports':
    command => "/usr/bin/find /opt/puppetlabs/server/data/puppetserver/reports/ -type f -mtime +${max_days} -delete",
    user    => 'root',
    hour    => 2,
    minute  => 0,
  }
}
