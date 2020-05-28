# puppetmaster_common

This module contains some typical Puppetmaster configurations:

* ::puppetmaster_common::r10k_deploy: setup r10k deploy script and make it run every hour (unless $autodeploy = false)
* ::puppetmaster_common::reports_purge: remove old yaml reports via a cronjob
* ::puppetmaster_common::packetfilter: configure firewall (IPv4 and IPv6) for Puppetserver, PuppetDB and HTTPS (Foreman/Puppetboard). Uses secure defaults (allow localhost only). Firewall rules use the 'default' tag and can be realized automatically if $realize_rules = true.

Optionally the Puppetmaster can be setup for being a Puppet Bolt controller that uses PuppetDB to automatically create an inventory.

## Usage

You can include each subclass individually. Everything expect the ::puppetmaster_common::packetfilter can be included with

    include ::puppetmaster_common

If you're on Puppet 6 you need the cron_core module. Puppet 5 has cron resource
built-in.

To set up Puppet Bolt (e.g. for feature branch testing) on the Puppetmaster:

* Create a PuppetDB inventory file template (for bolt-inventory-pdb)
* Create a bolt.yaml template
* Create a SSH keypair (or reuse an existing one)

Then set things up, e.g. in a profile:

    $ssh_private_key_content = lookup('profile::bolt_controller::ssh_private_key_content', String)
    
    class { 'puppetmaster_common::bolt_controller':
      puppetdb_url               => 'https://puppet.example.org:8081',
      inventory_template_content => template('profile/bolt-inventory-template.yaml.erb'),
      bolt_yaml_content          => template('profile/bolt.yaml.erb'),
      ssh_private_key_content    => $ssh_private_key_content,
    }
