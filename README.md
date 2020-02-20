# puppetmaster_common

Including this class adds some usual things to the Puppetmaster configuration

* Make r10k run every day
* Remove old yaml reports via a cronjob

## Usage

Just do

    include ::puppetmaster_common

If you're on Puppet 6 you need the cron_core module. Puppet 5 has cron resource
built-in.
