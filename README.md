# puppetmaster_common

This module contains some typical Puppetmaster configurations:

* ::puppetmaster_common::r10k_deploy: make r10k run every day
* ::puppetmaster_common::reports_purge: remove old yaml reports via a cronjob
* ::puppetmaster_common::packetfilter: configure firewall (IPv4 and IPv6) for Puppetserver, PuppetDB and HTTPS (Foreman/Puppetboard). Uses secure defaults (allow localhost only). Firewall rules use the 'default' tag and can be realized automatically if $realize_rules = true.

## Usage

You can include each subclass individually. Everything expect the ::puppetmaster_common::packetfilter can be included with

    include ::puppetmaster_common

If you're on Puppet 6 you need the cron_core module. Puppet 5 has cron resource
built-in.
