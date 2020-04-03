# @summary clean up old yaml reports
#
class puppetmaster_common::reports_purge {

  # Remove old reports to prevent disk space from filling up
  cron { 'remove-old-reports':
    command => '/usr/bin/find /opt/puppetlabs/server/data/puppetserver/reports/ -type f -mtime +7 -delete',
    user    => 'root',
    hour    => 2,
    minute  => 0,
  }
}
